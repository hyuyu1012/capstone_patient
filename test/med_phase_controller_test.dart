import 'package:capstone_patient/models/schedule_item.dart';
import 'package:capstone_patient/sensing/med_phase_controller.dart';
import 'package:capstone_patient/sensing/medication_scorer.dart' show MedPhase;
import 'package:flutter_test/flutter_test.dart';

/// 하루 스케줄:
///   08:00 식사 아침            (m1)
///   08:30 약   혈압약 · 식후    (d1, after → m1과 연결)
///   15:00 식사 간식            (m3, 뒤따르는 약 없는 식사)
///   22:00 약   수면제 · 식사무관 (d2, none → 시계 기반)
ScheduleItem _meal(String id, String time, String name) => ScheduleItem(
      id: id,
      kind: ScheduleKind.meal,
      name: name,
      time: time,
    );

ScheduleItem _med(String id, String time, String name, MealRelation rel) =>
    ScheduleItem(
      id: id,
      kind: ScheduleKind.med,
      name: name,
      dose: '1정',
      time: time,
      mealRelation: rel,
    );

final _schedule = <ScheduleItem>[
  _meal('m1', '08:00', '아침'),
  _med('d1', '08:30', '혈압약', MealRelation.after),
  _meal('m3', '15:00', '간식'),
  _med('d2', '22:00', '수면제', MealRelation.none),
];

MedPhaseController _controller() => MedPhaseController()..setSchedule(_schedule);

DateTime _at(int h, int m) => DateTime(2026, 6, 5, h, m);

void main() {
  group('식사(P1)', () {
    test('식사 예정시간 정각부터 창 안 → p1, 마이크 ON', () {
      final c = _controller();
      final d = c.decideAt(_at(8, 5)); // 08:00~09:30 창 (프리롤 제거: 정각 시작)
      expect(d.phase, MedPhase.p1);
      expect(d.targetId, 'm1');
      expect(d.micActive, isTrue);
    });

    test('프리롤 제거 → 식사 정각 전(07:55)엔 아직 p1 아님', () {
      final c = _controller();
      final d = c.decideAt(_at(7, 55));
      expect(d.phase, isNot(MedPhase.p1));
    });

    test('식사 미완료면 약 시간(08:30)이어도 여전히 p1 (식사 우선)', () {
      final c = _controller();
      final d = c.decideAt(_at(8, 30));
      expect(d.phase, MedPhase.p1, reason: '식사창(~09:30) 안이고 미완료라 P1 유지');
    });
  });

  group('식후약(after) — 식사완료 이벤트 트리거 + 폴백 없음', () {
    MedPhaseController eventCtrl() =>
        MedPhaseController(afterMedUsesMealEvent: true)..setSchedule(_schedule);

    test('식사 완료 시점부터 40분간 p2', () {
      final c = eventCtrl();
      c.notifyMealCompleted('m1', _at(8, 5)); // 이벤트 창 [08:05, 08:45]
      expect(c.decideAt(_at(8, 12)).phase, MedPhase.p2);
      expect(c.decideAt(_at(8, 12)).targetId, 'd1');
      expect(c.decideAt(_at(8, 44)).phase, MedPhase.p2, reason: '40분 끝 직전');
      expect(c.decideAt(_at(8, 46)).phase, isNot(MedPhase.p2),
          reason: '40분 지나면 닫힘');
    });

    test('식사 미감지면 식후약 시계 창을 열지 않는다 (폴백 포기)', () {
      // 식사(m1) 후 P1이 닫히는 시각보다 한참 뒤에 예정된 식후약(d9)으로 검증.
      // 식사완료 통지가 없으면 P1 종료 후에도 식후약 창이 열리지 않아야 한다.
      final c = MedPhaseController(afterMedUsesMealEvent: true)
        ..setSchedule([
          _meal('m1', '08:00', '아침'),
          _med('d9', '10:00', '식후약', MealRelation.after),
        ]);
      final d = c.decideAt(_at(10, 20)); // P1(~09:30) 밖, 옛 폴백 창 [10:00,10:40] 자리
      expect(d.phase, MedPhase.idle, reason: '폴백 포기 → 시계 창이 안 열린다');
    });

    test('mealId가 있으면 시간상 더 가까운 식사 대신 mealId 식사로 연결', () {
      // 약(09:30 식후)은 시간상 간식(09:00)이 더 가깝지만, mealId로 아침(m1)에
      // 연결돼 있다. 아침만 완료시켰을 때 창이 열리면 mealId 연결이 동작한 것.
      final c = MedPhaseController(afterMedUsesMealEvent: true)
        ..setSchedule([
          _meal('m1', '08:00', '아침'),
          _meal('ms', '09:00', '간식'),
          const ScheduleItem(
            id: 'd1',
            kind: ScheduleKind.med,
            name: '혈압약',
            dose: '1정',
            time: '09:30',
            mealRelation: MealRelation.after,
            mealId: 'm1',
          ),
        ]);
      c.notifyMealCompleted('m1', _at(8, 30)); // 연결된 아침만 완료
      final d = c.decideAt(_at(8, 40)); // 이벤트 창 [08:30, 09:10]
      expect(d.phase, MedPhase.p2);
      expect(d.targetId, 'd1');
    });

    test('연결된 식사를 스킵하면 식사 감지 없이 약 예정시간 시계 창으로 진행', () {
      final c = MedPhaseController(afterMedUsesMealEvent: true)
        ..setSchedule([
          _meal('m1', '08:00', '아침').copyWith(skipped: true),
          const ScheduleItem(
            id: 'd1',
            kind: ScheduleKind.med,
            name: '혈압약',
            dose: '1정',
            time: '08:30',
            mealRelation: MealRelation.after,
            mealId: 'm1',
          ),
        ]);
      // 식사완료 통지 없음. 그래도 식사가 스킵이라 약 시계 창 [08:30, 09:10]에서 p2.
      expect(c.decideAt(_at(8, 45)).phase, MedPhase.p2);
      expect(c.decideAt(_at(8, 45)).targetId, 'd1');
      // 스킵된 식사는 P1로 감시하지 않는다(식후약 창을 가리지 않음).
      expect(c.decideAt(_at(8, 10)).phase, isNot(MedPhase.p1));
    });
  });

  group('식전약 — 약 time부터 식사 시작 전까지 (04 스펙)', () {
    MedPhaseController beforeCtrl() => MedPhaseController()
      ..setSchedule([
        _meal('m1', '08:00', '아침'),
        const ScheduleItem(
          id: 'b1',
          kind: ScheduleKind.med,
          name: '식전약',
          dose: '1정',
          time: '07:40', // 식전 20분 → 창 [07:40, 08:00]
          mealRelation: MealRelation.before,
          mealId: 'm1',
        ),
      ]);

    test('약 time~식사 시작 사이엔 p2', () {
      final c = beforeCtrl();
      expect(c.decideAt(_at(7, 50)).phase, MedPhase.p2);
      expect(c.decideAt(_at(7, 50)).targetId, 'b1');
    });

    test('식사 시작(08:00)부터는 식전 창 종료 → p2 아님(식사 P1)', () {
      final c = beforeCtrl();
      expect(c.decideAt(_at(8, 5)).phase, isNot(MedPhase.p2));
    });
  });

  group('복용 확정 → 즉시 종료 (notifyMedTaken, 04 스펙)', () {
    test('확정 통지 후 그 약은 창 안이어도 감시 안 함', () {
      final c = _controller(); // d2(none) 22:00, 창 [22:00, 22:30]
      expect(c.decideAt(_at(22, 5)).phase, MedPhase.p2);
      c.notifyMedTaken('d2');
      expect(c.decideAt(_at(22, 5)).phase, isNot(MedPhase.p2));
    });
  });

  group('식사무관(none) — 시계 기반', () {
    test('약 time 근처 창 → p2 (식사 없이)', () {
      final c = _controller();
      final d = c.decideAt(_at(22, 5)); // [22:00, 22:30] (프리롤 제거)
      expect(d.phase, MedPhase.p2);
      expect(d.targetId, 'd2');
    });

    test('창 밖이면 idle', () {
      final c = _controller();
      final d = c.decideAt(_at(23, 30));
      expect(d.phase, MedPhase.idle);
      expect(d.micActive, isFalse);
    });
  });

  group('뒤따르는 약 없는 식사 완료', () {
    test('겨냥할 약 창이 없으면 → idle (gap 제거됨)', () {
      final c = _controller();
      c.notifyMealCompleted('m3', _at(15, 10));
      final d = c.decideAt(_at(15, 12)); // 완료 직후지만 겨냥 약 없음
      expect(d.phase, MedPhase.idle);
      expect(d.micActive, isFalse);
    });
  });

  group('대기(idle)', () {
    test('아무 일정도 없는 시간대 → idle, 마이크 OFF', () {
      final c = _controller();
      final d = c.decideAt(_at(3, 0));
      expect(d, MedPhaseDecision.idle);
    });
  });

  group('이미 복용한 약', () {
    test('taken=true 약은 창 안이어도 p2 트리거 안 함', () {
      final taken = _med('d2', '22:00', '수면제', MealRelation.none)
          .copyWith(taken: true);
      final c = MedPhaseController()
        ..setSchedule([_meal('m1', '08:00', '아침'), taken]);
      final d = c.decideAt(_at(22, 5));
      expect(d.phase, isNot(MedPhase.p2));
    });
  });
}
