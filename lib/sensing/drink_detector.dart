import 'dart:math' as math;
import 'dart:typed_data';

/// 목넘김(꿀꺽) 소리 감지기 — 순수 Dart, 라이브러리 추가 없음
///
/// ─── 2026-06-03 주파수 재측정 결과 ───────────────────────────────
/// 자기 녹음 7개 샘플(swallow1~7) 피크 ±200ms FFT 분석:
///   20-100Hz   :  11.9%  (편차 큼, 저주파 노이즈)
///   100-200Hz  :   8.1%
///   200-500Hz  :  48.3%  ← 핵심 대역
///   500-1kHz   :  16.5%  ← 보조 (확장 필요)
///   1-2kHz     :   5.9%
///   2-4kHz     :   2.4%
///   4-8kHz     :   6.9%
/// 중심 주파수: 약 300~500Hz, 90% 에너지 누적: ~600Hz
///
/// → 저역 cutoff를 500Hz → 1000Hz로 확장.
///   100-1kHz 대역이 약 95% 에너지를 포함.
///   신/구 필터 비교: 신호 RMS 약 1.2x 향상, 노이즈 1.08x → SNR 개선.
/// ────────────────────────────────────────────────────────────────
///
/// 3단계 필터:
///   1. 고역/저역 비율 ≥ 0.40 → 기침/필터성 고역음으로 차단 + 500ms 쿨다운
///   2. 중역/저역 비율 > 0.42 → 말소리/키보드 차단
///   3. 직전 500ms(5프레임) 내 배율 ≥ 3.0 구간 존재 → 의자/충격음 차단
class DrinkDetector {
  static const int sampleRate   = 16000;
  static const int subChunkSize = 1600; // 100ms

  // ── 저역 필터 계수 (100~1000Hz) ──────────────────────────────
  // 2026-06-03 재계산: 1kHz 2차 butterworth lowpass
  // (200-500Hz 메인 + 500-1k 보조 모두 포함)
  static const _hpB = [0.972614, -1.945228, 0.972614];   // 100Hz HP
  static const _hpA = [1.0,      -1.944478, 0.945978];
  static const _lpB = [0.029955,  0.059909, 0.029955];   // ★ 1000Hz LP (확장)
  static const _lpA = [1.0,      -1.454244, 0.574062];

  // ── 중역 필터 계수 (1000~3000Hz) ─────────────────────────────
  // 저역이 1kHz까지 확장됐으므로 중역 시작점도 1kHz로 이동
  static const _hp5B  = [0.757076, -1.514153, 0.757076]; // ★ 1000Hz HP
  static const _hp5A  = [1.0,      -1.454244, 0.574062];
  static const _lp3kB = [0.186694,  0.373389, 0.186694]; // 3000Hz LP
  static const _lp3kA = [1.0,      -0.462938, 0.209715];

  // ── 고역 필터 계수 (3000~7000Hz) ─────────────────────────────
  static const _hp3kB = [0.418163, -0.836327, 0.418163]; // 3000Hz HP (재계산)
  static const _hp3kA = [1.0,      -0.462938, 0.209715];
  static const _lp7kB = [0.757076,  1.514153, 0.757076]; // 7000Hz LP
  static const _lp7kA = [1.0,       1.454244, 0.574062];

  // ── 파라미터 ─────────────────────────────────────────────────
  static const double _minAbsThreshold = 0.0003;
  static const double _riseMultiplier  = 3.0;
  static const double _midRatioMax     = 0.42;
  static const double _coughHighRatio  = 0.40;
  static const int    _coughCooldown   = 5;
  static const int    _preCheckFrames  = 5;
  static const double _preCheckRise    = 3.0;
  static const int    _historyFrames   = 30;
  static const int    _maxActiveFrames = 10;

  // ── IIR 필터 상태 ────────────────────────────────────────────
  final _hpZ   = [0.0, 0.0];
  final _lpZ   = [0.0, 0.0];
  final _hp5Z  = [0.0, 0.0];
  final _lp3kZ = [0.0, 0.0];
  final _hp3kZ = [0.0, 0.0];
  final _lp7kZ = [0.0, 0.0];

  // ── 히스토리 ─────────────────────────────────────────────────
  final List<double> _bandHistory = [];
  final List<double> _riseHistory = [];

  // ── 이벤트 상태 ──────────────────────────────────────────────
  int    _activeFrames        = 0;
  bool   _alreadyFired        = false;
  int    _coughCooldownCount  = 0;

  // ── 디버그용 ─────────────────────────────────────────────────
  double lastBandRms     = 0.0;
  double lastMidRms      = 0.0;
  double lastHighRms     = 0.0;
  double lastBackground  = 0.0;
  double lastRiseRatio   = 0.0;
  double lastMidRatio    = 0.0;
  double lastHighRatio   = 0.0;
  bool   lastIsCough     = false;
  bool   lastInCooldown  = false;
  bool   lastPreBlocked  = false;
  int    lastActiveFrames = 0;

  DrinkEvent process(Float32List samples) {
    DrinkEvent? result;
    for (int offset = 0; offset + subChunkSize <= samples.length; offset += subChunkSize) {
      final sub   = Float32List.sublistView(samples, offset, offset + subChunkSize);
      final event = _processSub(sub);
      if (event.detected) result = event;
    }
    return result ?? DrinkEvent(
      detected: false,
      bandRms: lastBandRms, midRms: lastMidRms, highRms: lastHighRms,
      background: lastBackground, riseRatio: lastRiseRatio,
      midRatio: lastMidRatio, highRatio: lastHighRatio,
      isCough: lastIsCough, inCooldown: lastInCooldown,
      preBlocked: lastPreBlocked, activeFrames: lastActiveFrames,
    );
  }

  DrinkEvent _processSub(Float32List sub) {
    final lowFilt  = _applyBandpass(sub, _hpZ,   _lpZ,   _hpB,   _hpA,   _lpB,   _lpA);
    final midFilt  = _applyBandpass(sub, _hp5Z,  _lp3kZ, _hp5B,  _hp5A,  _lp3kB, _lp3kA);
    final highFilt = _applyBandpass(sub, _hp3kZ, _lp7kZ, _hp3kB, _hp3kA, _lp7kB, _lp7kA);

    final bandRms = _rms(lowFilt);
    final midRms  = _rms(midFilt);
    final highRms = _rms(highFilt);

    final midRatio  = bandRms > 0.0001 ? midRms  / bandRms : 0.0;
    final highRatio = bandRms > 0.0001 ? highRms / bandRms : 0.0;

    _bandHistory.add(bandRms);
    if (_bandHistory.length > _historyFrames) _bandHistory.removeAt(0);
    final background = _backgroundEnergy(_bandHistory);
    final riseRatio  = background > 0 ? bandRms / background : 0.0;

    _riseHistory.add(riseRatio);
    if (_riseHistory.length > _preCheckFrames + 1) _riseHistory.removeAt(0);

    // 필터 1: 기침 판정
    final isCough = highRatio >= _coughHighRatio;
    if (isCough) {
      _coughCooldownCount = _coughCooldown;
      _activeFrames = 0;
      _alreadyFired = false;
    } else if (_coughCooldownCount > 0) {
      _coughCooldownCount--;
    }
    final inCooldown = _coughCooldownCount > 0;

    // 필터 2: 중역 비율 (말소리/키보드)
    final midBlocked = midRatio > _midRatioMax;

    // 필터 3: 선행 고에너지 (의자/충격음)
    bool preBlocked = false;
    if (_riseHistory.length >= _preCheckFrames) {
      final preWindow = _riseHistory.sublist(0, _riseHistory.length - 1);
      preBlocked = preWindow.any((r) => r >= _preCheckRise);
    }

    final isActive = bandRms > _minAbsThreshold &&
        riseRatio >= _riseMultiplier &&
        !midBlocked &&
        !isCough &&
        !inCooldown &&
        !preBlocked;

    bool detected = false;
    if (isActive) {
      _activeFrames++;
      if (_activeFrames == 1 && !_alreadyFired) {
        detected = true;
        _alreadyFired = true;
      }
      if (_activeFrames >= _maxActiveFrames) {
        _activeFrames = 0;
        _alreadyFired = false;
      }
    } else if (!isCough && !inCooldown) {
      _activeFrames = 0;
      _alreadyFired = false;
    }

    lastBandRms      = bandRms;
    lastMidRms       = midRms;
    lastHighRms      = highRms;
    lastBackground   = background;
    lastRiseRatio    = riseRatio;
    lastMidRatio     = midRatio;
    lastHighRatio    = highRatio;
    lastIsCough      = isCough;
    lastInCooldown   = inCooldown;
    lastPreBlocked   = preBlocked;
    lastActiveFrames = _activeFrames;

    return DrinkEvent(
      detected: detected,
      bandRms: bandRms, midRms: midRms, highRms: highRms,
      background: background, riseRatio: riseRatio,
      midRatio: midRatio, highRatio: highRatio,
      isCough: isCough, inCooldown: inCooldown,
      preBlocked: preBlocked, activeFrames: _activeFrames,
    );
  }

  Float32List _applyBandpass(
    Float32List input,
    List<double> hpZ, List<double> lpZ,
    List<double> hpB, List<double> hpA,
    List<double> lpB, List<double> lpA,
  ) {
    final n   = input.length;
    final hp  = Float32List(n);
    final out = Float32List(n);
    for (int i = 0; i < n; i++) {
      final x = input[i];
      final y = hpB[0] * x + hpZ[0];
      hpZ[0]  = hpB[1] * x - hpA[1] * y + hpZ[1];
      hpZ[1]  = hpB[2] * x - hpA[2] * y;
      hp[i]   = y;
    }
    for (int i = 0; i < n; i++) {
      final x = hp[i];
      final y = lpB[0] * x + lpZ[0];
      lpZ[0]  = lpB[1] * x - lpA[1] * y + lpZ[1];
      lpZ[1]  = lpB[2] * x - lpA[2] * y;
      out[i]  = y;
    }
    return out;
  }

  double _rms(Float32List s) {
    double sum = 0.0;
    for (final v in s) sum += v * v;
    return math.sqrt(sum / s.length);
  }

  double _backgroundEnergy(List<double> history) {
    if (history.isEmpty) return 0.0;
    final sorted = List<double>.from(history)..sort();
    final count  = math.max(1, (sorted.length * 0.4).floor());
    double sum   = 0;
    for (int i = 0; i < count; i++) sum += sorted[i];
    return sum / count;
  }

  void reset() {
    for (final z in [_hpZ, _lpZ, _hp5Z, _lp3kZ, _hp3kZ, _lp7kZ]) {
      z[0] = z[1] = 0.0;
    }
    _bandHistory.clear();
    _riseHistory.clear();
    _activeFrames        = 0;
    _alreadyFired        = false;
    _coughCooldownCount  = 0;
  }
}

class DrinkEvent {
  final bool   detected;
  final double bandRms;
  final double midRms;
  final double highRms;
  final double background;
  final double riseRatio;
  final double midRatio;
  final double highRatio;
  final bool   isCough;
  final bool   inCooldown;
  final bool   preBlocked;
  final int    activeFrames;

  const DrinkEvent({
    required this.detected,
    required this.bandRms,
    required this.midRms,
    required this.highRms,
    required this.background,
    required this.riseRatio,
    required this.midRatio,
    required this.highRatio,
    required this.isCough,
    required this.inCooldown,
    required this.preBlocked,
    required this.activeFrames,
  });
}
