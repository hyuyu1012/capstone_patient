import 'dart:collection';
import 'dart:math';

/// Flutter의 foundation에 동일한 VoidCallback이 있지만, 이 파일을 순수 Dart로
/// 테스트 가능하게 유지하기 위해 직접 정의한다.
typedef VoidCallback = void Function();

// ─────────────────────────────────────────────────────────────
// 복약 감지 카테고리 (2026-06-04 재설계)
// ─────────────────────────────────────────────────────────────
//
// 5개 카테고리. 각 카테고리는 점수 윈도우(120초) 내에서 단 1회만 점수가 누적된다.
// (같은 카테고리의 클래스가 여러 번 발화되어도 점수는 추가되지 않음)
//
//   water     20점 — 물 따르기/마시기 (Pour, Fill, Water, Liquid, Slosh 등)
//                    ※ Gargling(양치 오탐) 제거됨 (2026-06-04)
//   package   20점 — 약봉지/약통 (Tearing, Crumpling, Rattle)
//   swallow   30점 — 목넘김 (CNN+IIR 상호검증). 실질적 핵심 신호이므로 최고 가중치.
//   stationary20점 — 가속도계 정지
//   etc       10점 — 목 가다듬기, 클릭 (Throat clearing, Clicking)
//                    ※ Glass/Chink 제거 — Glass는 설거지 차단 신호로 이동 (2026-06-04)
// ─────────────────────────────────────────────────────────────
//
// [2026-06-04 변경 요약]
//   - 점수: water 30→20, swallow 20→30 (핵심 신호 가중)
//   - 윈도우: 75초 → 120초
//   - 자동확정(100점) 제거 — 80점 이상이면 무조건 Gemini 검증
//     (swallow 신뢰도 미확보 상태 → Gemini를 최종 안전망으로. 캡스톤 심사 대비)
//   - 순서 체인 완화: package→water→swallow 강제 X.
//     swallow가 "package·water 둘 다보다 뒤"이기만 하면 OK (순서 무관 앵커 방식)
//   - foodConflict: 3→4회 발동, 해제 5분→15초, P2 활성 시에만 적용
//   - 설거지 차단(신규): Glass + Dishes/pots 동시 감지 → 15초 차단
//   - P1/P2 단계(phase) 개념 도입: 감시 엔진은 끊김 없이 동작, 단계만 컨텍스트로 구분
// ─────────────────────────────────────────────────────────────
enum MedCategory { water, package, swallow, stationary, etc }

/// 트리거 종류
///   geminiVerify : 80점 이상 → 항상 Gemini로 사용자 확인.
///
/// [2026-06-04] autoConfirmed(자동 확정) 경로 제거.
///   swallow 신뢰도가 충분히 확보되지 않은 상태에서 자동 확정은 위험하고,
///   캡스톤 심사 시 "센서만으로 복약을 단정하느냐"는 지적을 받을 수 있어
///   모든 트리거는 Gemini 음성 재확인을 거치도록 일원화한다.
enum MedTriggerType { geminiVerify }

/// 트리거가 막힌 사유 (UI 표시용).
///   none           : 정상 (대기 중 또는 트리거됨)
///   foodConflict   : 씹는 소리 지속 → 식사/간식 중 → 차단 (P2에서만 적용)
///   dishwashing    : Glass + Dishes/pots 동시 → 설거지 중 → 차단 (2026-06-04 신규)
///   invalidSequence: 점수는 충분하나 swallow가 앵커 조건을 못 채움
///   sessionExpired : (예약) 세션 만료
enum MedBlockReason { none, foodConflict, dishwashing, invalidSequence, sessionExpired }

/// 감시 단계(phase). 감시 엔진(MedicationScorer)은 단계와 무관하게 끊김 없이
/// 동작하며, 단계는 "트리거를 어떻게 처리할지"의 컨텍스트로 쓰인다.
///
///   idle : 감시 비활성. 점수만 계산, 트리거 없음.
///   p1   : 식사지도(P1) 진행 중. 점수는 매기되 복약 트리거는 발생시키지 않는다(무시).
///          식사 중 발생하는 삼킴/물소리는 복약으로 보지 않는다.
///   gap  : P1 종료 ~ P2 시작 사이 공백기. 이 구간 감지는 어느 약인지 특정할 수
///          없으므로 unknown으로 트리거 → Gemini가 "약 드셨어요?(어떤 약?)" 재확인.
///   p2   : 복약지도(P2, 식전/식후 모드) 진행 중. 트리거되면 그 모드가 들고 있는
///          대상 약으로 확정 처리한다(식전약을 늦게 먹었어도 식후모드면 식후약으로).
///          foodConflict·설거지 차단을 모두 적용.
///
/// [참고] 복약 감시를 "별도 프로그램"으로 분리하지 않는다. 감시는 하나의 연속된
/// 프로세스이고, P1/gap/P2는 그 위에 얹힌 단계 구분일 뿐이다.
enum MedPhase { idle, p1, gap, p2 }

/// 트리거 발동 시 콜백에 전달되는 결과 객체.
class MedTriggerResult {
  final MedTriggerType type;
  final int score;
  final bool orderValid;

  /// 트리거가 발생한 단계. p1이면 보호자 알림 없이 taken 처리만,
  /// p2이면 기존 P2 흐름(Gemini 재확인 후 처리)을 따른다.
  final MedPhase phase;

  final Map<MedCategory, DateTime> firstSeen;
  final List<ScoringEvent> events;

  const MedTriggerResult({
    required this.type,
    required this.score,
    required this.orderValid,
    required this.phase,
    required this.firstSeen,
    required this.events,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'score': score,
        'orderValid': orderValid,
        'phase': phase.name,
        'firstSeen': firstSeen.map((k, v) => MapEntry(k.name, v.toIso8601String())),
        'events': events.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() =>
      'MedTriggerResult(type=${type.name}, score=$score, orderValid=$orderValid, phase=${phase.name})';
}

/// 점수화 타임라인에 기록되는 단일 이벤트.
class ScoringEvent {
  final DateTime timestamp;
  final String className;
  final MedCategory category;
  final int score;
  final double confidence;

  const ScoringEvent({
    required this.timestamp,
    required this.className,
    required this.category,
    required this.score,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'className': className,
        'category': category.name,
        'score': score,
        'confidence': double.parse(confidence.toStringAsFixed(3)),
      };

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] ${category.name} | $className (+$score, conf=${confidence.toStringAsFixed(2)})';
}

/// 내부용: 가속도계 샘플 (밀리초 타임스탬프 + 선형가속도 크기).
class _AccelSample {
  final int tMs;
  final double mag;
  _AccelSample(this.tMs, this.mag);
}

/// YAMNet 분류 결과 + M_swallow(CNN+IIR) + 가속도계를 통합 점수화하여
/// 복약 의식(ritual) 패턴을 감지하는 클래스.
class MedicationScorer {
  // ─────────────────────────────────────────────────────────
  // 튜닝 상수 (2026-06-04 결정)
  // ─────────────────────────────────────────────────────────

  /// YAMNet confidence가 이 값 이상인 결과만 점수 반영.
  static const double kConfidenceThreshold = 0.3;

  /// 물 계열은 YAMNet 점수가 낮게 뜨는 편이라 별도 완화한다.
  static const double kWaterConfidenceThreshold = 0.12;

  /// Gemini 검증 임계값. 이 점수 이상이면 (단계에 맞는) 트리거를 발생시킨다.
  /// [2026-06-04] 자동확정(100점) 경로를 없앴으므로 이 값이 유일한 트리거 기준이다.
  static const int kGeminiVerifyThreshold = 80;

  /// 외부에서 참조하는 트리거 임계값 (UI 기준선용).
  static const int kTriggerThreshold = kGeminiVerifyThreshold;

  /// 점수 누적 윈도우. (75초 → 120초)
  /// 식후 복약: 밥 끝 → 약 꺼냄 → 물 따름 → 삼킴까지 전체 흐름을 담기 위해 확장.
  static const Duration kScoreWindow = Duration(seconds: 120);

  // ── M_chew 음식 오탐(foodConflict) 판단 ──
  /// 최근 이 시간 내 M_chew 발생 횟수를 센다.
  static const Duration kChewWindow = Duration(seconds: 30);

  /// 이 횟수 이상 M_chew가 감지되면 foodConflict ON (식사/간식 의심).
  /// [2026-06-04] 3 → 4로 롤백. 3회는 너무 쉽게 걸려 식후 복약까지 막혔고,
  /// 해제 시간을 15초로 짧게 가져가므로 4회로 올려도 실수 차단 시 빠르게 풀린다.
  static const int kChewConflictCount = 4;

  /// foodConflict 해제: 마지막 M_chew 이후 이 시간이 지나면 해제.
  /// [2026-06-04] 5분 → 15초로 대폭 단축.
  ///   기존 5분은 "식사 후 바로 복약"을 통째로 막는 부작용이 있었다.
  ///   목적은 "지금 씹는 중"일 때만 막는 것이므로, 씹기가 멈추면 빠르게 해제한다.
  static const Duration kChewClearAfter = Duration(seconds: 15);

  // ── 설거지 차단 (2026-06-04 신규) ──
  // Glass(435) + Dishes/pots(439)가 가까운 시점에 함께 감지되면 설거지로 판단.
  // (단독 감지는 식탁에서 컵을 내려놓는 소리일 수 있어 차단하지 않는다.)
  // 두 클래스가 모두 이 시간 내에 감지되어 있어야 "동시"로 인정한다.
  static const Duration kDishPairWindow = Duration(seconds: 5);

  /// 설거지 차단 해제: 마지막 설거지 신호(둘 중 더 최근) 이후 이 시간 경과 시 해제.
  static const Duration kDishClearAfter = Duration(seconds: 15);

  // ── 카테고리별 점수 (2026-06-04) ──
  // water 30→20, swallow 20→30. 합계는 100 유지.
  static const Map<MedCategory, int> _categoryScores = {
    MedCategory.water: 20,
    MedCategory.package: 20,
    MedCategory.swallow: 30,
    MedCategory.stationary: 20,
    MedCategory.etc: 10,
  };

  // ── YAMNet 클래스 → 카테고리 매핑 (yamnet_class_map.csv 기준) ──
  // 물 (20점): Water, Water tap, Liquid, Slosh, Pour, Fill, Pump
  //            ※ Gargling(51) 제거 — 식후 양치 오탐 위험 (2026-06-04)
  // 약 (20점): Tearing, Crumpling, Rattle
  // 기타 (10점): Throat clearing, Clicking
  //            ※ Glass(435) → 설거지 차단으로 이동, Chink(436) 제거 (2026-06-04)
  static const Map<int, MedCategory> _classToCategory = {
    // ── 물 ──
    282: MedCategory.water,    // Water
    364: MedCategory.water,    // Water tap, faucet
    438: MedCategory.water,    // Liquid
    440: MedCategory.water,    // Slosh
    443: MedCategory.water,    // Pour
    446: MedCategory.water,    // Fill (with liquid)
    448: MedCategory.water,    // Pump (liquid)
    // ── 약 ──
    130: MedCategory.package,  // Rattle (약통 흔들기)
    473: MedCategory.package,  // Crumpling, crinkling
    474: MedCategory.package,  // Tearing
    // ── 기타 ──
    43:  MedCategory.etc,      // Throat clearing (실측: 물 마시다 사레들림에 감지됨)
    485: MedCategory.etc,      // Clicking (약통 뚜껑/블리스터 팩)
  };

  // ── 설거지 판단용 클래스 (점수 카테고리 아님, negative signal) ──
  static const int kClassGlass = 435;      // Glass
  static const int kClassDishes = 439;     // Dishes, pots, and pans

  // 디버그/로그용 클래스 이름
  static const Map<int, String> _classNames = {
    282: 'Water', 364: 'Water tap', 438: 'Liquid',
    440: 'Slosh', 443: 'Pour', 446: 'Fill', 448: 'Pump',
    130: 'Rattle', 473: 'Crumpling', 474: 'Tearing',
    43: 'Throat clearing', 485: 'Clicking',
    435: 'Glass', 439: 'Dishes/pots',
  };

  // ── 가속도계 / 정지 판단 (2026-06-03 완화) ──

  /// userAccelerometerEventStream()의 선형가속도 크기(m/s²)가 이 값 미만이면 '정지'.
  /// userAccelerometer는 중력이 제거된 값이므로 정지 시 0에 가깝고 1.5로 충분히 구분됨.
  static const double kStationaryAccelThreshold = 1.5;

  /// 정지 판단 sliding window 길이.
  static const int kWindowMs = 5000;
  static const int kBucketMs = 100;
  static const int kBucketCount = kWindowMs ~/ kBucketMs; // 50

  /// 유효 버킷(데이터 있는 버킷)이 이 개수 이상일 때만 정지 판정 시작.
  /// 최소 1초(10버킷) 데이터가 쌓여야 판단 — 앱 시작 직후 오판 방지.
  static const int kMinValidBuckets = 10;

  /// 유효 버킷 중 이 비율 이상이 정지여야 전체 정지로 판단.
  static const double kStationaryRatio = 0.60;

  // ─────────────────────────────────────────────────────────
  // 상태
  // ─────────────────────────────────────────────────────────

  /// 트리거 콜백 (Gemini 검증 트리거).
  void Function(MedTriggerResult)? onTrigger;

  /// 현재 감시 단계. main.dart에서 P1/P2 흐름에 맞춰 setPhase()로 갱신한다.
  /// idle이면 점수 평가는 하되 트리거를 발생시키지 않는다.
  MedPhase _phase = MedPhase.idle;

  /// 카테고리별 윈도우 내 첫 감지 시각.
  /// 같은 카테고리 재발화는 점수 누적 X, 시각 갱신 X (가장 빠른 발생 시각 유지).
  final Map<MedCategory, DateTime> _firstSeen = {};

  /// 각 카테고리가 최근에 어떤 클래스로 감지됐는지 (디버그용).
  final Map<MedCategory, String> _lastClassByCategory = {};

  /// 점수 부여된 이벤트 로그 (감지 시에만 기록 — 로그 옵션 b).
  final List<ScoringEvent> _eventLog = [];

  /// 가속도계 샘플 버퍼.
  final List<_AccelSample> _accelSamples = [];

  bool _isStationary = false;
  DateTime? _stationaryEnteredAt; // 정지 진입 시각 (카테고리 첫 감지 시각으로 사용)

  /// M_chew 감지 타임스탬프 큐 (foodConflict 판단용).
  /// 큐 방식: 오래된 항목은 앞에서 제거, 새 항목은 뒤에 추가.
  final ListQueue<DateTime> _chewTimestamps = ListQueue<DateTime>();

  /// 마지막 M_chew 감지 시각 (foodConflict 해제 판단용).
  DateTime? _lastChewTime;

  /// 설거지 판단용: Glass / Dishes 마지막 감지 시각 (2026-06-04).
  DateTime? _lastGlassTime;
  DateTime? _lastDishesTime;

  /// 같은 사이클에서 중복 트리거 방지.
  /// onTrigger 호출 후 reset()이 불릴 때까지 true로 유지된다.
  /// [2026-06-04] 자동확정 제거로 _autoTriggered 플래그도 제거. _geminiTriggered만 사용.
  bool _geminiTriggered = false;

  /// 마지막 평가에서 트리거가 막힌 사유 (UI 표시용).
  MedBlockReason lastBlockedReason = MedBlockReason.none;

  MedicationScorer({this.onTrigger});

  // ─────────────────────────────────────────────────────────
  // 단계(phase) 제어
  // main.dart의 P1/P2 흐름에서 호출한다.
  //   - P1 시작(식사 감지 시작) 시          : setPhase(MedPhase.p1)
  //   - P1 종료 후 P2 시작 전 공백기         : setPhase(MedPhase.gap)
  //   - P2(식전/식후 모드) 시작 시           : setPhase(MedPhase.p2)
  //   - 모든 창이 닫히면                     : setPhase(MedPhase.idle)
  // 단계가 바뀌어도 누적 점수/로그는 유지된다(감시는 연속). 트리거 가능 여부와
  // 트리거 결과의 의미(p2=확정 / gap=unknown)만 단계에 따라 달라진다.
  // ─────────────────────────────────────────────────────────
  void setPhase(MedPhase phase) {
    _phase = phase;
  }

  MedPhase get phase => _phase;

  // ─────────────────────────────────────────────────────────
  // 입력 1: YAMNet 분류 결과
  // ─────────────────────────────────────────────────────────
  void addYamnetResult(int classIndex, double confidence) {
    final now = DateTime.now();
    _pruneExpired(now);

    // ── 설거지 negative signal 가로채기 (2026-06-04) ──
    // Glass/Dishes는 점수 카테고리가 아니라 설거지 차단 판단용이다.
    // confidence 기준은 일반 임계값(0.3)을 그대로 적용한다.
    if (classIndex == kClassGlass || classIndex == kClassDishes) {
      if (confidence >= kConfidenceThreshold) {
        if (classIndex == kClassGlass) {
          _lastGlassTime = now;
        } else {
          _lastDishesTime = now;
        }
        // 로그에 0점 negative signal로 남김 (사후 분석용)
        _eventLog.add(ScoringEvent(
          timestamp: now,
          className: '${_classNames[classIndex]} (설거지 신호)',
          category: MedCategory.etc, // 점수 매핑과 무관 (0점 표시용)
          score: 0,
          confidence: confidence,
        ));
        _evaluate(now);
      }
      return; // 점수 카테고리로 넘기지 않음
    }

    final category = _classToCategory[classIndex];
    if (category == null) return;
    if (confidence < _confidenceThresholdFor(category)) return;

    final className = _classNames[classIndex] ?? 'class_$classIndex';
    _registerCategoryHit(category, className, confidence, now);
  }

  double _confidenceThresholdFor(MedCategory category) {
    if (category == MedCategory.water) return kWaterConfidenceThreshold;
    return kConfidenceThreshold;
  }

  // ─────────────────────────────────────────────────────────
  // 입력 2: M_swallow (CNN + IIR 상호검증 결과)
  // main.dart에서 두 감지기가 모두 목넘김을 감지한 순간 호출.
  // confidence가 별도로 없으면 1.0으로 호출하면 된다.
  // ─────────────────────────────────────────────────────────
  void addSwallowDetection({double confidence = 1.0}) {
    final now = DateTime.now();
    _pruneExpired(now);
    _registerCategoryHit(
      MedCategory.swallow,
      'M_swallow (CNN+IIR)',
      confidence,
      now,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 입력 2-1: M_chew (음식 오탐 negative signal)
  // main.dart에서 YAMNet chewingScore >= chewingThreshold일 때 호출.
  // 점수에는 영향을 주지 않으며, foodConflict 판단에만 사용한다.
  // ─────────────────────────────────────────────────────────
  void addChewDetection({double confidence = 1.0}) {
    final now = DateTime.now();
    _lastChewTime = now;
    _chewTimestamps.addLast(now);
    _pruneChew(now);
    // 로그에는 0점 negative signal로 남김 (사후 분석용)
    _eventLog.add(ScoringEvent(
      timestamp: now,
      className: 'M_chew (음식 오탐 신호)',
      category: MedCategory.swallow, // 카테고리 점수 매핑과 무관 (0점 표시용)
      score: 0,
      confidence: confidence,
    ));
    _evaluate(now);
  }

  /// kChewWindow(30초) 밖의 M_chew 타임스탬프 제거 (큐 앞에서).
  void _pruneChew(DateTime now) {
    final cutoff = now.subtract(kChewWindow);
    while (_chewTimestamps.isNotEmpty &&
        _chewTimestamps.first.isBefore(cutoff)) {
      _chewTimestamps.removeFirst();
    }
  }

  /// 음식 오탐 상태 여부.
  /// - 최근 kChewWindow(30초) 내 M_chew가 kChewConflictCount(4)회 이상 → true
  /// - 단, 마지막 M_chew 이후 kChewClearAfter(15초) 경과 시 자동 해제
  ///
  /// [2026-06-04] 이 getter는 "현재 씹는 중인가"를 나타낸다. 해제 시간을 15초로
  /// 짧게 둬서, 식사가 끝나면 곧바로 풀려 식후 복약 감지를 막지 않도록 했다.
  /// 실제 차단 적용은 _evaluate()에서 단계(p2)일 때만 수행한다.
  bool get hasFoodConflict {
    final now = DateTime.now();
    if (_lastChewTime != null &&
        now.difference(_lastChewTime!) > kChewClearAfter) {
      return false;
    }
    _pruneChew(now);
    return _chewTimestamps.length >= kChewConflictCount;
  }

  /// 설거지 상태 여부 (2026-06-04 신규).
  /// - Glass와 Dishes/pots가 모두, 서로 kDishPairWindow(5초) 이내에 감지되어 있고
  /// - 그 중 더 최근 신호가 kDishClearAfter(15초) 이내일 때 → true
  ///
  /// 단독(Glass만, Dishes만) 감지는 설거지로 보지 않는다(식탁에서 컵 내려놓기 등).
  bool get hasDishwashing {
    final now = DateTime.now();
    final g = _lastGlassTime;
    final d = _lastDishesTime;
    if (g == null || d == null) return false;

    // 두 신호가 5초 이내로 가까운가 (동시성)
    final pairGap = g.isAfter(d) ? g.difference(d) : d.difference(g);
    if (pairGap > kDishPairWindow) return false;

    // 더 최근 신호가 15초 이내인가 (아직 유효한가)
    final latest = g.isAfter(d) ? g : d;
    return now.difference(latest) <= kDishClearAfter;
  }

  // ─────────────────────────────────────────────────────────
  // 입력 3: 선형가속도 (userAccelerometerEventStream, 중력 제거됨)
  // main.dart에서 userAccelerometerEventStream()을 사용해야 함.
  // sensors_plus: accelerometerEventStream(중력 포함) ← 사용 X
  //               userAccelerometerEventStream(중력 제거) ← 사용 O
  // ─────────────────────────────────────────────────────────
  void updateAccelerometer(double x, double y, double z) {
    final now = DateTime.now();
    // userAccelerometer는 중력이 이미 제거됨 → 바로 magnitude 계산
    final magnitude = sqrt(x * x + y * y + z * z);
    _accelSamples.add(_AccelSample(now.millisecondsSinceEpoch, magnitude));
    _updateStationaryState(now);
    _pruneExpired(now);
    _evaluate(now);
  }

  // ─────────────────────────────────────────────────────────
  // 내부: 카테고리 첫 감지 등록 + 평가
  // ─────────────────────────────────────────────────────────
  void _registerCategoryHit(
    MedCategory cat,
    String className,
    double confidence,
    DateTime now,
  ) {
    // 윈도우 내 첫 발생만 카운트
    if (_firstSeen.containsKey(cat)) {
      _lastClassByCategory[cat] = className; // 디버그용 갱신은 OK
      _evaluate(now);
      return;
    }

    _firstSeen[cat] = now;
    _lastClassByCategory[cat] = className;
    _eventLog.add(ScoringEvent(
      timestamp: now,
      className: className,
      category: cat,
      score: _categoryScores[cat]!,
      confidence: confidence,
    ));
    _evaluate(now);
  }

  // ─────────────────────────────────────────────────────────
  // 정지 상태 계산 (5초 sliding window, 100ms 버킷 50개)
  // 유효 버킷(데이터 있는 버킷) 기반 비율 판정 — 초반 데이터 부족 문제 해결
  // ─────────────────────────────────────────────────────────
  void _updateStationaryState(DateTime now) {
    final nowMs = now.millisecondsSinceEpoch;
    final cutoff = nowMs - kWindowMs;
    _accelSamples.removeWhere((s) => s.tMs < cutoff);

    final sums   = List<double>.filled(kBucketCount, 0);
    final counts = List<int>.filled(kBucketCount, 0);

    for (final s in _accelSamples) {
      var idx = (nowMs - s.tMs) ~/ kBucketMs;
      if (idx < 0) idx = 0;
      if (idx >= kBucketCount) continue;
      sums[idx]   += s.mag;
      counts[idx] ++;
    }

    var stationaryBuckets = 0;
    var validBuckets      = 0;
    for (var i = 0; i < kBucketCount; i++) {
      if (counts[i] == 0) continue; // 데이터 없는 버킷 제외
      validBuckets++;
      if (sums[i] / counts[i] < kStationaryAccelThreshold) stationaryBuckets++;
    }

    final wasStationary = _isStationary;
    // 최소 kMinValidBuckets(1초)이 쌓인 후, 유효 버킷의 60% 이상이 정지여야 통과
    _isStationary = validBuckets >= kMinValidBuckets &&
        stationaryBuckets >= (validBuckets * kStationaryRatio).round();

    // 정지 진입/이탈 시 카테고리 첫 감지 시각 관리
    if (_isStationary && !wasStationary) {
      _stationaryEnteredAt = now;
      // 카테고리에도 등록 (점수 시스템 통일)
      if (!_firstSeen.containsKey(MedCategory.stationary)) {
        _firstSeen[MedCategory.stationary] = now;
        _eventLog.add(ScoringEvent(
          timestamp: now,
          className: 'Stationary (정지 진입)',
          category: MedCategory.stationary,
          score: _categoryScores[MedCategory.stationary]!,
          confidence: 1.0,
        ));
      }
    } else if (!_isStationary && wasStationary) {
      // 정지에서 빠져나옴 — 윈도우 만료까지 점수는 유지 (이미 firstSeen 등록됨)
      _stationaryEnteredAt = null;
    }
  }

  // ─────────────────────────────────────────────────────────
  // 만료 처리: 120초 윈도우 밖으로 나간 firstSeen 항목 제거
  // ─────────────────────────────────────────────────────────
  void _pruneExpired(DateTime now) {
    final cutoff = now.subtract(kScoreWindow);
    _firstSeen.removeWhere((cat, t) => t.isBefore(cutoff));
    if (_firstSeen.isEmpty) {
      // 모든 점수가 만료되면 재트리거 가능 상태로 복귀
      _geminiTriggered = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // 평가 + 트리거 (2026-06-04 재작성)
  //
  // 단계(phase)에 따라 차단·트리거 정책이 달라진다:
  //   idle : 점수만 계산, 트리거 없음.
  //   p1   : 식사 중. 약을 먹어도 복약으로 보지 않는다 → 점수가 차도 트리거 안 함(무시).
  //          식사 소음(삼킴/물소리)과 복약을 구분할 수 없기 때문.
  //   gap  : P1 종료~P2 시작 공백기. 트리거하되 어느 약인지 특정 불가 → Gemini가
  //          재확인(main에서 unknown 처리). foodConflict/설거지 차단은 적용한다
  //          (공백기에도 설거지·잔여 식사 오탐 가능성이 있으므로).
  //   p2   : 복약 창. foodConflict·설거지 차단 적용. 80점 이상이면 트리거 →
  //          그 모드의 약으로 확정 처리(main).
  //
  // 자동확정(autoConfirmed)은 제거되었다. 트리거는 항상 geminiVerify로 통일하고,
  // gap/p2 구분은 result.phase로 main에 전달한다(Gemini가 최종 안전망).
  // ─────────────────────────────────────────────────────────
  void _evaluate(DateTime now) {
    // idle·p1은 트리거하지 않는다.
    //   idle: 감시 창 없음. p1: 식사 중이라 복약으로 보지 않음(무시).
    if (_phase == MedPhase.idle || _phase == MedPhase.p1) {
      lastBlockedReason = MedBlockReason.none;
      return;
    }

    final score = _computeScore();
    final orderValid = _isExpectedOrder();

    // ── 차단 정책 (gap·p2) ──
    // 식사 중(p1)이 아닌, 복약을 노리는 구간이므로 식사/설거지 오탐을 차단한다.
    if (hasFoodConflict) {
      lastBlockedReason = MedBlockReason.foodConflict;
      return;
    }
    if (hasDishwashing) {
      lastBlockedReason = MedBlockReason.dishwashing;
      return;
    }

    // ── 트리거: 80점 이상이면 Gemini 검증 (단계 정보 포함) ──
    // result.phase가 gap이면 main에서 unknown으로, p2면 해당 모드 약으로 처리.
    final reachesGemini = score >= kGeminiVerifyThreshold;
    if (reachesGemini && !_geminiTriggered) {
      _geminiTriggered = true;
      lastBlockedReason = MedBlockReason.none;
      onTrigger?.call(MedTriggerResult(
        type: MedTriggerType.geminiVerify,
        score: score,
        orderValid: orderValid,
        phase: _phase,
        firstSeen: Map.unmodifiable(_firstSeen),
        events: List.unmodifiable(_eventLog),
      ));
      return;
    }

    // 점수는 충분하나 swallow 앵커 조건 미충족으로 막힌 경우 사유 기록
    if (reachesGemini && !orderValid) {
      lastBlockedReason = MedBlockReason.invalidSequence;
    } else {
      lastBlockedReason = MedBlockReason.none;
    }
  }

  /// 현재 firstSeen에 누적된 카테고리들의 점수 합.
  int _computeScore() {
    var sum = 0;
    for (final cat in _firstSeen.keys) {
      sum += _categoryScores[cat] ?? 0;
    }
    return sum;
  }

  /// swallow 앵커 검증 (2026-06-04 완화).
  ///
  /// 기존: package → water → swallow 순서를 엄격히 강제했다.
  /// 변경: 물을 먼저 따를 수도, 약봉지를 먼저 뜯을 수도 있으므로 package·water의
  ///       선후관계는 따지지 않는다. 대신 실질적 핵심 신호인 swallow가
  ///       "package와 water 둘 다보다 시간상 뒤"이기만 하면 정상으로 본다.
  ///       (먹는 행위인 삼킴은 준비 동작 이후에 와야 자연스럽다)
  ///
  /// - package, water, swallow 세 카테고리가 모두 있어야 하고
  /// - swallow가 package·water의 첫 감지 시각보다 뒤이면 true.
  /// - 하나라도 빠지거나 swallow가 앞서면 false → invalidSequence (Gemini가 재확인).
  /// - stationary와 etc는 판정에 영향 없음.
  bool _isExpectedOrder() {
    final pkg = _firstSeen[MedCategory.package];
    final wat = _firstSeen[MedCategory.water];
    final swl = _firstSeen[MedCategory.swallow];
    if (pkg == null || wat == null || swl == null) return false;
    // swallow가 package·water 둘 다보다 뒤(앵커). package/water 간 순서는 무관.
    return swl.isAfter(pkg) && swl.isAfter(wat);
  }

  // ─────────────────────────────────────────────────────────
  // 외부 노출 API
  // ─────────────────────────────────────────────────────────

  /// 현재 누적 점수 (만료 카테고리 제외).
  int get currentScore {
    _pruneExpired(DateTime.now());
    return _computeScore();
  }

  /// 현재 정지 상태인가? (UI용)
  bool get isStationary => _isStationary;

  /// 현재 swallow 앵커 조건을 충족하는가? (UI/디버그용)
  bool get isOrderValid => _isExpectedOrder();

  /// 현재 설거지로 판단되는가? (UI/디버그용, 2026-06-04)
  bool get isDishwashing => hasDishwashing;

  /// 카테고리별 현재 감지 상태.
  Map<MedCategory, bool> get categoryStatus => {
        for (final c in MedCategory.values) c: _firstSeen.containsKey(c)
      };

  /// 카테고리별 첫 감지 시각.
  Map<MedCategory, DateTime> get firstSeenTimes =>
      Map.unmodifiable(_firstSeen);

  /// 점수 부여 이벤트 로그 (감지 시에만 기록됨).
  List<ScoringEvent> get eventLog => List.unmodifiable(_eventLog);

  /// 사후 검증 / Firestore 전송용 JSON 직렬화.
  List<Map<String, dynamic>> eventLogAsJson() =>
      _eventLog.map((e) => e.toJson()).toList();

  /// 트리거 후 다음 복약 사이클 준비. firstSeen / 트리거 플래그 초기화.
  /// eventLog는 보존 (사후 검증용). 완전 지우려면 clearLog() 사용.
  /// [참고] phase는 여기서 건드리지 않는다(단계 전환은 main이 setPhase로 관리).
  void reset() {
    _firstSeen.clear();
    _lastClassByCategory.clear();
    _chewTimestamps.clear();
    _lastChewTime = null;
    _lastGlassTime = null;
    _lastDishesTime = null;
    _geminiTriggered = false;
    lastBlockedReason = MedBlockReason.none;
  }

  /// 이벤트 로그까지 완전 초기화.
  void clearLog() {
    _eventLog.clear();
  }
}
