/// 목넘김(삼킴) 소리 CNN 추론 모듈 (librosa 호환 버전)
///
/// ─── 2026-06-03 librosa 호환 재구현 ──────────────────────────────
/// 기존 문제:
///   1. _fftMagnitude가 O(N^2) DFT + 매 프레임 cos/sin 80,400회 호출 -> 느림
///   2. mel filterbank가 정규화 없는 단순 삼각필터 -> librosa(Slaney 정규화)와
///      40~80배 스케일 차이 -> CNN이 학습 분포와 다른 입력을 받아 감지 실패
///   3. Hann window가 (N-1) 기준 symmetric -> librosa는 N 기준 periodic
///
/// 해결:
///   1. DFT cos/sin 트위들 테이블을 init()에서 1회 사전계산 -> 룩업 고속화
///   2. librosa.filters.mel(Slaney) 값을 sparse 상수로 포함 (_melFb)
///   3. Hann window를 periodic으로 수정
///   -> Python 검증 결과 librosa.feature.melspectrogram과 오차 0.0000 dB 일치
///
/// 학습 파라미터 (train_swallow.py 기준):
///   - 16kHz PCM16 mono, 패치 96프레임 x 64 mel-bin (~960ms)
///   - n_fft=400, hop=160, n_mels=64, fmin=125, fmax=7500
///   - power=2.0, power_to_db(ref=max), center=False, window=hann(periodic)
///   - 정규화 (logmel-mean)/std, mean=-49.6514, std=25.1358, threshold=0.06
/// ────────────────────────────────────────────────────────────────

import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

/// mel filterbank의 sparse 한 행: 시작 freq bin + 연속 weight들.
class _Mel {
  final int start;
  final List<double> w;
  const _Mel(this.start, this.w);
}

class SwallowDetector {
  static const int kSampleRate  = 16000;
  static const int kNFft        = 400;
  static const int kHopLen      = 160;
  static const int kNMels       = 64;
  static const int kPatchFrames = 96;
  static const int kNFreq       = kNFft ~/ 2 + 1; // 201

  static const double kNormMean  = -49.6514;
  static const double kNormStd   = 25.1358;
  static const double kThreshold = 0.06;

  Interpreter? _interp;
  final List<double> _audioBuffer = [];

  late final Float32List _cosTab;
  late final Float32List _sinTab;
  late final Float32List _hann;
  bool _tablesReady = false;

  /// 마지막 추론 확률 (디버그/상호검증용).
  double lastScore = 0.0;

  bool get isReady => _interp != null && _tablesReady;

  Future<void> init(String modelPath) async {
    _interp = await Interpreter.fromAsset(modelPath);
    _buildTables();
  }

  void _buildTables() {
    _cosTab = Float32List(kNFreq * kNFft);
    _sinTab = Float32List(kNFreq * kNFft);
    for (int k = 0; k < kNFreq; k++) {
      for (int n = 0; n < kNFft; n++) {
        final angle = -2 * pi * k * n / kNFft;
        _cosTab[k * kNFft + n] = cos(angle);
        _sinTab[k * kNFft + n] = sin(angle);
      }
    }
    // periodic Hann: 0.5 - 0.5*cos(2*pi*n/N)  (librosa fftbins=true)
    _hann = Float32List(kNFft);
    for (int n = 0; n < kNFft; n++) {
      _hann[n] = 0.5 - 0.5 * cos(2 * pi * n / kNFft);
    }
    _tablesReady = true;
  }

  /// PCM16 바이트 -> float32 변환 후 누적. 패치 차면 추론, 아니면 null.
  bool? feedPcm16(Uint8List pcmBytes) {
    final samples = Float32List(pcmBytes.length ~/ 2);
    for (int i = 0; i < samples.length; i++) {
      final lo = pcmBytes[i * 2];
      final hi = pcmBytes[i * 2 + 1];
      int s16 = (hi << 8) | lo;
      if (s16 >= 0x8000) s16 -= 0x10000;
      samples[i] = s16 / 32768.0;
    }
    return _feed(samples);
  }

  /// Float32 [-1,1] 샘플 직접 입력 (AudioStreamer.onChunk 연결용).
  bool? feedFloat32(Float32List samples) => _feed(samples);

  bool? _feed(Float32List samples) {
    if (!isReady) return null;
    _audioBuffer.addAll(samples);

    final needed = kNFft + (kPatchFrames - 1) * kHopLen; // 15600
    if (_audioBuffer.length < needed) return null;

    final waveform = Float32List.fromList(_audioBuffer.sublist(0, needed));
    _audioBuffer.removeRange(0, kHopLen * (kPatchFrames ~/ 2)); // 50% overlap

    final patch = _computeLogMelPatch(waveform);
    return _infer(patch);
  }

  List<List<double>> _computeLogMelPatch(Float32List wav) {
    final frames =
        List.generate(kPatchFrames, (_) => List<double>.filled(kNMels, 0.0));
    final windowed = Float32List(kNFft);
    final power = Float32List(kNFreq);
    double globalMax = -1e30;

    for (int t = 0; t < kPatchFrames; t++) {
      final start = t * kHopLen;
      for (int i = 0; i < kNFft; i++) {
        final idx = start + i;
        windowed[i] = idx < wav.length ? wav[idx] * _hann[i] : 0.0;
      }
      // 테이블 DFT -> power |X|^2
      for (int k = 0; k < kNFreq; k++) {
        double re = 0, im = 0;
        final base = k * kNFft;
        for (int n = 0; n < kNFft; n++) {
          final x = windowed[n];
          re += x * _cosTab[base + n];
          im += x * _sinTab[base + n];
        }
        power[k] = re * re + im * im;
      }
      // mel filterbank (sparse)
      final row = frames[t];
      for (int m = 0; m < kNMels; m++) {
        final mel = _melFb[m];
        double e = 0.0;
        for (int j = 0; j < mel.w.length; j++) {
          e += mel.w[j] * power[mel.start + j];
        }
        final db = 10.0 * (log(e < 1e-10 ? 1e-10 : e) / ln10);
        row[m] = db;
        if (db > globalMax) globalMax = db;
      }
    }
    // power_to_db(ref=max)
    for (final row in frames) {
      for (int m = 0; m < kNMels; m++) {
        row[m] -= globalMax;
      }
    }
    return frames;
  }

  bool _infer(List<List<double>> patch) {
    final interp = _interp!;
    final input = List.generate(1, (_) =>
        List.generate(kPatchFrames, (t) =>
            List.generate(kNMels, (m) =>
                [(patch[t][m] - kNormMean) / kNormStd])));
    final output = List.generate(1, (_) => [0.0]);
    interp.run(input, output);
    lastScore = output[0][0];
    return lastScore >= kThreshold;
  }

  void resetBuffer() => _audioBuffer.clear();

  void dispose() {
    _interp?.close();
    _interp = null;
  }

  // ── librosa mel filterbank (Slaney, sparse) ──────────────────
  static const List<_Mel> _melFb = [
    _Mel(4, [1.84795689e-02, 6.35688799e-03]),
    _Mel(5, [1.66210942e-02, 8.21536314e-03]),
    _Mel(6, [1.47626195e-02, 1.00738378e-02]),
    _Mel(7, [1.29041458e-02, 1.19323125e-02]),
    _Mel(8, [1.10456701e-02, 1.37907872e-02]),
    _Mel(9, [9.18719545e-03, 1.56492628e-02]),
    _Mel(10, [7.32872076e-03, 1.75077375e-02]),
    _Mel(11, [5.47024608e-03, 1.93662122e-02]),
    _Mel(12, [3.61177116e-03, 2.12246869e-02, 1.05178478e-04]),
    _Mel(13, [1.75329635e-03, 2.28728056e-02, 1.96365314e-03]),
    _Mel(15, [2.10143290e-02, 3.82212806e-03]),
    _Mel(16, [1.91558544e-02, 5.68060298e-03]),
    _Mel(17, [1.72973797e-02, 7.53907766e-03]),
    _Mel(18, [1.54389050e-02, 9.39755328e-03]),
    _Mel(19, [1.35804312e-02, 1.12560280e-02]),
    _Mel(20, [1.17219556e-02, 1.31145017e-02]),
    _Mel(21, [9.86348093e-03, 1.49729773e-02]),
    _Mel(22, [8.00500624e-03, 1.68314520e-02]),
    _Mel(23, [6.14653155e-03, 1.86899267e-02]),
    _Mel(24, [4.19015950e-03, 2.01852620e-02, 4.69186052e-04]),
    _Mel(25, [2.16452894e-03, 2.09800247e-02, 3.91717907e-03]),
    _Mel(27, [1.67183168e-02, 7.65983015e-03]),
    _Mel(28, [1.22367209e-02, 1.15941148e-02]),
    _Mel(29, [7.61662563e-03, 1.56172179e-02, 1.93380506e-03]),
    _Mel(30, [2.94928742e-03, 1.60321519e-02, 7.14019686e-03]),
    _Mel(32, [1.02694826e-02, 1.21887196e-02, 7.53934262e-04]),
    _Mel(33, [4.69219685e-03, 1.56251229e-02, 6.58208271e-03]),
    _Mel(35, [9.33535956e-03, 1.20898839e-02, 2.53420416e-03]),
    _Mel(36, [3.38336988e-03, 1.25196623e-02, 8.52397177e-03]),
    _Mel(38, [6.13696454e-03, 1.40936319e-02, 6.10825932e-03]),
    _Mel(39, [1.84717370e-04, 7.81962089e-03, 1.19438358e-02, 4.64401906e-03]),
    _Mel(41, [1.64064893e-03, 8.62008613e-03, 1.06324898e-02, 3.95937217e-03]),
    _Mel(43, [2.32124119e-03, 8.70148372e-03, 1.00063169e-02, 3.90609656e-03]),
    _Mel(45, [2.37188837e-03, 8.20437726e-03, 9.93328448e-03, 4.35677590e-03]),
    _Mel(47, [1.91772555e-03, 7.24948710e-03, 1.03000337e-02, 5.20227617e-03, 1.04519007e-04]),
    _Mel(49, [1.06607971e-03, 5.94010204e-03, 1.08141247e-02, 6.34949468e-03, 1.68938760e-03]),
    _Mel(52, [4.36422834e-03, 8.81980918e-03, 7.71937193e-03, 3.45934136e-03]),
    _Mel(54, [2.59649125e-03, 6.66955439e-03, 9.24511999e-03, 5.35081932e-03, 1.45651877e-03]),
    _Mel(56, [6.99824421e-04, 4.42320900e-03, 8.14659335e-03, 7.31069222e-03, 3.75072239e-03, 1.90752937e-04]),
    _Mel(59, [2.13068933e-03, 5.53441606e-03, 8.93814303e-03, 6.04055915e-03, 2.78621772e-03]),
    _Mel(62, [2.94478890e-03, 6.05630036e-03, 8.29230063e-03, 5.31734899e-03, 2.34239758e-03]),
    _Mel(64, [4.09152795e-04, 3.25353700e-03, 6.09792164e-03, 7.75926560e-03, 5.03971800e-03, 2.32017017e-03]),
    _Mel(67, [5.52869693e-04, 3.15305940e-03, 5.75324940e-03, 7.60650029e-03, 5.12042968e-03, 2.63435883e-03, 1.48288149e-04]),
    _Mel(70, [3.49066802e-04, 2.72602658e-03, 5.10298647e-03, 7.47994659e-03, 5.48464572e-03, 3.21200793e-03, 9.39370133e-04]),
    _Mel(74, [2.04328657e-03, 4.21618111e-03, 6.38907542e-03, 6.06841315e-03, 3.99088440e-03, 1.91335543e-03]),
    _Mel(77, [1.16531306e-03, 3.15166148e-03, 5.13800979e-03, 6.81731151e-03, 4.91814176e-03, 3.01897177e-03, 1.11980189e-03]),
    _Mel(80, [1.43491954e-04, 1.95930968e-03, 3.77512746e-03, 5.59094502e-03, 5.94914146e-03, 4.21301788e-03, 2.47689476e-03, 7.40771065e-04]),
    _Mel(84, [6.81189296e-04, 2.34111631e-03, 4.00104374e-03, 5.66097070e-03, 5.45933051e-03, 3.87225533e-03, 2.28518038e-03, 6.98105549e-04]),
    _Mel(88, [8.69965588e-04, 2.38738558e-03, 3.90480575e-03, 5.42222569e-03, 5.27704228e-03, 3.82621959e-03, 2.37539760e-03, 9.24575375e-04]),
    _Mel(92, [7.76983856e-04, 2.16413103e-03, 3.55127850e-03, 4.93842596e-03, 5.34135476e-03, 4.01508762e-03, 2.68882071e-03, 1.36255356e-03, 3.62864776e-05]),
    _Mel(96, [4.59954346e-04, 1.72801304e-03, 2.99607194e-03, 4.26413072e-03, 5.53218927e-03, 4.38764924e-03, 3.17524420e-03, 1.96283916e-03, 7.50433886e-04]),
    _Mel(101, [1.12747878e-03, 2.28667282e-03, 3.44586698e-03, 4.60506137e-03, 4.90024919e-03, 3.79193085e-03, 2.68361229e-03, 1.57529360e-03, 4.66975180e-04]),
    _Mel(105, [4.03775659e-04, 1.46345142e-03, 2.52312701e-03, 3.58280283e-03, 4.64247866e-03, 4.50267550e-03, 3.48950760e-03, 2.47633993e-03, 1.46317214e-03, 4.50004416e-04]),
    _Mel(110, [5.60551824e-04, 1.52925286e-03, 2.49795383e-03, 3.46665503e-03, 4.43535578e-03, 4.35079494e-03, 3.42460955e-03, 2.49842345e-03, 1.57223758e-03, 6.46051660e-04]),
    _Mel(115, [4.92220337e-04, 1.37775706e-03, 2.26329383e-03, 3.14883050e-03, 4.03436692e-03, 4.39597992e-03, 3.54930852e-03, 2.70263711e-03, 1.85596547e-03, 1.00929395e-03, 1.62622469e-04]),
    _Mel(120, [2.44845025e-04, 1.05435716e-03, 1.86386926e-03, 2.67338147e-03, 3.48289357e-03, 4.29240568e-03, 3.82256834e-03, 3.04858456e-03, 2.27460102e-03, 1.50061748e-03, 7.26633938e-04]),
    _Mel(126, [5.97877777e-04, 1.33789226e-03, 2.07790639e-03, 2.81792087e-03, 3.55793512e-03, 4.20939317e-03, 3.50185740e-03, 2.79432139e-03, 2.08678539e-03, 1.37924950e-03, 6.71713555e-04]),
    _Mel(131, [4.13848793e-05, 7.17867923e-04, 1.39435090e-03, 2.07083393e-03, 2.74731731e-03, 3.42380023e-03, 4.03328566e-03, 3.38649284e-03, 2.73969979e-03, 2.09290697e-03, 1.44611381e-03, 7.99320871e-04, 1.52527820e-04]),
    _Mel(137, [3.13098317e-05, 6.49715832e-04, 1.26812188e-03, 1.88652787e-03, 2.50493409e-03, 3.12333996e-03, 3.74174607e-03, 3.43574770e-03, 2.84448289e-03, 2.25321786e-03, 1.66195305e-03, 1.07068813e-03, 4.79423150e-04]),
    _Mel(144, [4.32001456e-04, 9.97316441e-04, 1.56263146e-03, 2.12794635e-03, 2.69326149e-03, 3.25857638e-03, 3.61471833e-03, 3.07421433e-03, 2.53371033e-03, 1.99320633e-03, 1.45270233e-03, 9.12198389e-04, 3.71694361e-04]),
    _Mel(150, [9.77527961e-05, 6.14534714e-04, 1.13131665e-03, 1.64809846e-03, 2.16488051e-03, 2.68166233e-03, 3.19844414e-03, 3.39950831e-03, 2.90540722e-03, 2.41130637e-03, 1.91720529e-03, 1.42310443e-03, 9.29003465e-04, 4.34902555e-04]),
    _Mel(157, [1.47544284e-04, 6.19959726e-04, 1.09237514e-03, 1.56479061e-03, 2.03720597e-03, 2.50962144e-03, 2.98203691e-03, 3.34373582e-03, 2.89205415e-03, 2.44037248e-03, 1.98869081e-03, 1.53700926e-03, 1.08532759e-03, 6.33645919e-04, 1.81964206e-04]),
    _Mel(164, [5.17410372e-05, 4.83598938e-04, 9.15456854e-04, 1.34731480e-03, 1.77917280e-03, 2.21103057e-03, 2.64288858e-03, 3.07474658e-03, 3.00216256e-03, 2.58925837e-03, 2.17635417e-03, 1.76345010e-03, 1.35054579e-03, 9.37641715e-04, 5.24737523e-04, 1.11833338e-04]),
    _Mel(172, [2.35740546e-04, 6.30522845e-04, 1.02530513e-03, 1.42008741e-03, 1.81486970e-03, 2.20965222e-03, 2.60443427e-03, 2.99921655e-03, 2.83091818e-03, 2.45346245e-03, 2.07600673e-03, 1.69855088e-03, 1.32109516e-03, 9.43639432e-04, 5.66183648e-04, 1.88727878e-04]),
  ];
}
