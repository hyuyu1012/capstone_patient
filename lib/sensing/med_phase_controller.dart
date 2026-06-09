// ─────────────────────────────────────────────────────────────
// med_phase_controller.dart  (2026-06-05 신규)
//
// "무전병" — 스케줄 시간표를 보고 알맞은 때에 감시 단계(MedPhase)와 마이크
// on/off를 결정한다. MedicationScorer는 setPhase()로 단계만 받으면 어떻게
// 행동할지 다 알지만, "지금이 어느 시간대인지"는 누군가 알려줘야 한다. 이
// 컨트롤러가 그 역할이다.
//
// [책임 분리 — 옵션 (1)]
//   이 컨트롤러는 "언제 어느 phase냐"만 결정한다. 실제 Firestore 쓰기
//   (toMealUpdate / toScheduleUpdate)는 상위 서비스(MedSensingService, C단계)가
//   onChanged 콜백을 받아 처리한다. 컨트롤러는 Firebase를 모른다.
//
// [설계 원칙 — YAMNet 모듈과 동일하게 순수 Dart로 테스트 가능하게 유지]
//   - Flutter/Firebase에 의존하지 않는다(입력은 ScheduleItem 리스트 + 시각).
//   - 시간 판정은 decideAt(now)로 분리해 단위 테스트가 가능하다.
//   - 실제 앱에서는 start()의 Timer가 주기적으로 decideAt(DateTime.now())를
//     호출하고, 단계가 바뀌면 onChanged 콜백을 쏜다.
//
// [식전/식후/식사무관 분기 — ScheduleItem.mealRelation]
//   after (식후)  : "식사 종료"가 트리거. 연결된 식사가 완료되면(M_chew 멈춤
//                   → notifyMealCompleted) 그 시점부터 P2 창을 연다.
//                   식사를 끝내 감지 못 하면 약 time을 시계 백업으로 사용.
//   before(식전)  : 식사와 무관하게 약 time 기준 시계 창. (식사 전이라 식사종료
//                   이벤트를 기다릴 수 없음)
//   none (식사무관): 약 time 기준 시계 창. P1 식사 단계를 건너뛴다.
//
//   → 즉 "식사 종료 이벤트"가 필요한 건 after 하나뿐. before/none은 시계 기반.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import '../models/schedule_item.dart';
import 'medication_scorer.dart' show MedPhase;

/// 컨트롤러가 매 시점 산출하는 결정.
class MedPhaseDecision {
  /// scorer.setPhase()에 넘길 단계.
  final MedPhase phase;

  /// 이 창이 겨냥하는 스케줄 항목 id (없으면 null).
  /// p2면 그 약 id, p1이면 그 식사 id. idle은 null.
  final String? targetId;

  /// 마이크를 켜야 하는가. idle이면 false, 그 외엔 true.
  final bool micActive;

  /// UI/디버그용 사람이 읽을 사유.
  final String reason;

  const MedPhaseDecision({
    required this.phase,
    required this.targetId,
    required this.micActive,
    required this.reason,
  });

  static const idle = MedPhaseDecision(
    phase: MedPhase.idle,
    targetId: null,
    micActive: false,
    reason: '대기(idle) — 감시할 일정 없음',
  );

  /// 단계 전환 감지용 동등성 (reason은 비교에서 제외 — 표시만 바뀐 건 무시).
  @override
  bool operator ==(Object other) =>
      other is MedPhaseDecision &&
      other.phase == phase &&
      other.targetId == targetId &&
      other.micActive == micActive;

  @override
  int get hashCode => Object.hash(phase, targetId, micActive);

  @override
  String toString() =>
      'MedPhaseDecision(${phase.name}, target=$targetId, mic=$micActive, "$reason")';
}

/// 스케줄 기반 감시 단계 컨트롤러.
class MedPhaseController {
  // ── 튜닝 상수 (창 크기) ──────────────────────────────────────
  /// [2026-06-09] 식사 전 프리롤(-10분) 제거. P1은 식사 예정시간 정각부터 시작한다.
  /// 이전 -10분은 식사 직전의 식전약 시계 창을 P1이 가리는 부작용이 있었다.
  static const Duration kPreMeal = Duration.zero;

  /// 식사 종료가 끝내 감지되지 않을 때 P1 창을 닫는 최대 길이.
  /// [2026-06-09] 40→90분. 식후약을 "식사완료" 트리거로 여는 정책으로 바꾸면서,
  /// 밥이 예정보다 늦어도(최대 +90분) 식사를 감지해 식후약 창을 열 수 있게 확대.
  /// 이 시각까지 식사완료를 못 잡으면 식후약 창은 열리지 않는다(폴백 없음).
  static const Duration kMealMaxDuration = Duration(minutes: 90);

  /// 시계 기반 약 창: 예정시간 정각부터 시작한다.
  /// [2026-06-09] 프리롤(-10분) 제거. 약 예정시간 이전을 미리 감시하지 않는다.
  static const Duration kPreMed = Duration.zero;

  /// 약 창: 시작 시점으로부터 이 만큼 동안 감시. (식전·식사무관 공용)
  static const Duration kPostMed = Duration(minutes: 30);

  /// 식후약 전용 감시 창 길이. 식사완료 후 약통 꺼냄·물·삼킴까지 더 길게 보려고
  /// 식전·식사무관(30분)과 분리한다. [2026-06-09 신설]
  static const Duration kPostMedAfter = Duration(minutes: 40);

  /// 식후약과 식사를 연결하는 최대 간격(이보다 먼 식사는 무관한 식사로 본다).
  static const Duration kMealAssocMaxGap = Duration(hours: 2);

  /// 라이브 평가 주기.
  static const Duration kTick = Duration(seconds: 20);

  // ── 콜백 ─────────────────────────────────────────────────────
  /// 결정이 바뀔 때마다 호출. 상위 서비스가 setPhase + 마이크 제어에 연결.
  final void Function(MedPhaseDecision decision)? onChanged;

  /// [2026-06-05] 식후약 "식사완료-이벤트" 트리거 스위치.
  ///   false(기본): 식후약도 식전/식사무관과 똑같이 약 time 시계 창으로 동작한다.
  ///   true       : 연결된 식사가 완료된 시점부터 식후약 P2 창을 연다(이벤트).
  /// [2026-06-09] MedSensingService(io)에서 true로 켰다. 식사를 끝내 감지 못 하면
  ///   식후약 창을 열지 않는다(시계 폴백 포기) — 90분 P1이 폴백 창을 통째로 가리는
  ///   문제가 있어, 식후약은 "식사완료가 실제로 감지된 경우"에만 동작한다.
  /// ※ 식사완료 감지·기록(setMeal)은 이 값과 무관하게 계속 동작한다.
  ///   여기서 끄는 것은 "식사완료 → 식후약 창 열기" 연결뿐이다.
  final bool afterMedUsesMealEvent;

  MedPhaseController({this.onChanged, this.afterMedUsesMealEvent = false});

  // ── 상태 ─────────────────────────────────────────────────────
  List<ScheduleItem> _meals = const [];
  List<ScheduleItem> _meds = const [];

  /// 식사 id → 완료(M_chew 멈춤 감지) 시각.
  final Map<String, DateTime> _mealCompletedAt = {};

  /// 이번 세션에서 복약이 감지·확정된 약 id. [2026-06-09] 04 스펙 "복용 완료되면
  /// 즉시 종료" — Firestore taken 왕복을 기다리지 않고 로컬에서 즉시 창을 닫는다.
  final Set<String> _confirmedMeds = {};

  Timer? _timer;
  MedPhaseDecision _current = MedPhaseDecision.idle;
  MedPhaseDecision get current => _current;

  /// 해당 식사가 아직 유효한 감시 대상인가(목록에 있고 스킵 아님). 식사 창을
  /// 벗어날 때 '시간 종료'와 '삭제/스킵으로 빠짐'을 구분하는 데 쓴다 —
  /// 후자라면 eaten으로 마무리하면 안 된다.
  bool hasMeal(String mealId) =>
      _meals.any((m) => m.id == mealId && !m.skipped);

  // ── 입력 1: 스케줄 갱신 (ScheduleService 스트림에서) ──────────
  void setSchedule(List<ScheduleItem> items) {
    _meals = items.where((i) => i.kind == ScheduleKind.meal).toList();
    _meds = items.where((i) => i.kind == ScheduleKind.med).toList();
    _evaluateNow();
  }

  // ── 입력 2: 식사 종료 이벤트 (식사 상태머신/스코어러에서) ─────
  /// 해당 식사가 완료됐음을 알린다. 식후약(after)의 P2 창을 여는 트리거.
  void notifyMealCompleted(String mealId, DateTime at) {
    _mealCompletedAt[mealId] = at;
    _evaluateNow();
  }

  /// 복약 감지·확정 통지(스코어러 80점 트리거). 해당 약 감시 창을 즉시 닫는다.
  void notifyMedTaken(String medId) {
    _confirmedMeds.add(medId);
    _evaluateNow();
  }

  /// 자정 넘어가거나 새 하루가 시작될 때 완료 기록을 비운다(선택).
  void clearMealCompletions() {
    _mealCompletedAt.clear();
    _confirmedMeds.clear();
    _evaluateNow();
  }

  // ── 라이브 구동 ──────────────────────────────────────────────
  void start() {
    _timer ??= Timer.periodic(kTick, (_) => _evaluateNow());
    _evaluateNow();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();

  void _evaluateNow() {
    final next = decideAt(DateTime.now());
    final changed = next != _current;
    _current = next;
    if (changed) onChanged?.call(next);
  }

  // ─────────────────────────────────────────────────────────────
  // 순수 판정: 주어진 시각에 어떤 단계여야 하는가. (단위 테스트 진입점)
  //
  // 우선순위:
  //   1) 식사 중(P1)  — 완료 안 된 식사의 창 안이면 최우선. 식사 소음과
  //                     복약을 구분 못 하므로 이때 약 감지는 무시(scorer가 처리).
  //   2) 복약(P2)     — 활성 약 창이 있으면. 식후=식사완료 트리거, 그 외=시계.
  //   3) 대기(idle)   — 그 외. 마이크 off.
  // ─────────────────────────────────────────────────────────────
  MedPhaseDecision decideAt(DateTime now) {
    // 1) 식사(P1)
    for (final m in _meals) {
      if (m.skipped) continue; // 보호자가 건너뛴 식사는 감시하지 않음
      if (_mealCompletedAt.containsKey(m.id)) continue; // 이미 끝난 식사
      final mealTime = _todayAt(m.time, now);
      final start = mealTime.subtract(kPreMeal);
      final end = mealTime.add(kMealMaxDuration);
      if (!now.isBefore(start) && now.isBefore(end)) {
        return MedPhaseDecision(
          phase: MedPhase.p1,
          targetId: m.id,
          micActive: true,
          reason: '식사 감시(P1): ${m.name}',
        );
      }
    }

    // 2) 복약(P2)
    for (final med in _meds) {
      // 복용 완료(taken)/로컬 확정/건너뛴 약은 감시 안 함 (확정 시 즉시 종료).
      if (med.taken || med.skipped || _confirmedMeds.contains(med.id)) continue;
      final win = _medWindow(med, now);
      if (win != null && !now.isBefore(win.start) && now.isBefore(win.end)) {
        final rel = med.mealRelation.label;
        return MedPhaseDecision(
          phase: MedPhase.p2,
          targetId: med.id,
          micActive: true,
          reason: '복약 감시(P2): ${med.name}${rel.isEmpty ? '' : ' ($rel)'}',
        );
      }
    }

    // 3) 대기
    return MedPhaseDecision.idle;
  }

  // ── 약 한 개의 감시 창 [start, end) 계산 ─────────────────────
  ({DateTime start, DateTime end})? _medWindow(ScheduleItem med, DateTime now) {
    final medTime = _todayAt(med.time, now);

    // 식후약 이벤트 트리거 (afterMedUsesMealEvent=true). 연결된 식사가 완료된
    // 시점부터 kPostMedAfter(40분) 동안 창을 연다.
    if (med.mealRelation == MealRelation.after && afterMedUsesMealEvent) {
      final meal = _mealFor(med, now);
      // [2026-06-09] 연결된 식사를 보호자가 "건너뜀"으로 표시 → 오늘 그 끼니는
      // 없다는 명시적 신호. 식사 감지를 기다리지 않고 약 예정시간 시계 창으로
      // 진행한다(P1이 안 열려 가려질 일도 없음).
      if (meal != null && meal.skipped) {
        return (start: medTime, end: medTime.add(kPostMedAfter));
      }
      final completedAt = meal == null ? null : _mealCompletedAt[meal.id];
      if (completedAt != null) {
        return (start: completedAt, end: completedAt.add(kPostMedAfter));
      }
      // 식사를 끝내 감지 못 하면(스킵도 아님) 창을 열지 않는다(폴백 포기).
      return null;
    }

    // 식전약: 약 time부터 "연결된 식사 시작 전까지" 감시(식전 O분 = 그 구간 길이).
    // 식사가 시작되면 식전 창은 닫힌다. 연결 식사가 없으면 기본 시계 창으로.
    if (med.mealRelation == MealRelation.before) {
      final meal = _mealFor(med, now);
      if (meal != null) {
        final mealTime = _todayAt(meal.time, now);
        if (mealTime.isAfter(medTime)) {
          return (start: medTime, end: mealTime);
        }
      }
    }

    // 식사무관 / (연결 식사 없는) 식전 / (이벤트 OFF인) 식후 → 약 time 시계 창.
    return (start: medTime.subtract(kPreMed), end: medTime.add(kPostMed));
  }

  // ── 식후약과 연결할 식사 찾기 ────────────────────────────────
  // 1) 보호자 앱이 연결한 mealId가 있으면 그 식사로 정확히 연결한다.
  // 2) 없으면(구버전 데이터) 약 time 이전이면서 가장 가까운 식사로 추정한다.
  //    (밥 먹고 → 그 약을 먹는 자연스러운 순서) kMealAssocMaxGap(2시간) 초과는 제외.
  ScheduleItem? _mealFor(ScheduleItem med, DateTime now) {
    final linkedId = med.mealId;
    if (linkedId != null) {
      for (final m in _meals) {
        if (m.id == linkedId) return m;
      }
    }
    final medTime = _todayAt(med.time, now);
    ScheduleItem? best;
    DateTime? bestTime;
    for (final m in _meals) {
      final mt = _todayAt(m.time, now);
      if (mt.isAfter(medTime)) continue;
      if (medTime.difference(mt) > kMealAssocMaxGap) continue;
      if (bestTime == null || mt.isAfter(bestTime)) {
        best = m;
        bestTime = mt;
      }
    }
    return best;
  }

  // "HH:mm" + 오늘 날짜 → DateTime.
  DateTime _todayAt(String hhmm, DateTime now) {
    final p = hhmm.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(p[0]),
      int.parse(p[1]),
    );
  }
}
