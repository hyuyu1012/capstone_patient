import 'package:capstone_patient/models/schedule_item.dart';
import 'package:capstone_patient/sensing/med_phase_controller.dart';
import 'package:capstone_patient/sensing/medication_scorer.dart' show MedPhase;
import 'package:flutter_test/flutter_test.dart';

/// 하루 스케줄:
///   08:00 식사 아침            (m1)
///   08:30 약   혈압약 · 식후    (d1, after → m1과 연결)
///   15:00 식사 간식            (m3, 뒤따르는 약 없음 → gap 검증용)
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
    test('식사 예정시간 전후 창 안 → p1, 마이크 ON', () {
      final c = _controller();
      final d = c.decideAt(_at(7, 55)); // 07:50~08:40 창
      expect(d.phase, MedPhase.p1);
      expect(d.targetId, 'm1');
      expect(d.micActive, isTrue);
    });

    test('식사 미완료면 약 시간(08:30)이어도 여전히 p1 (식사 우선)', () {
      final c = _controller();
      final d = c.decideAt(_at(8, 30));
      expect(d.phase, MedPhase.p1, reason: '식사창(~08:40) 안이고 미완료라 P1 유지');
    });
  });

  group('식후약(after) — 기본: 시계 기반 (afterMedUsesMealEvent=false)', () {
    test('약 time 시계 창에서 p2 (혈압약)', () {
      final c = _controller();
      final d = c.decideAt(_at(8, 45)); // 시계 창 [08:20, 09:00]
      expect(d.phase, MedPhase.p2);
      expect(d.targetId, 'd1');
    });

    test('식사 완료를 알려도 식후약 창은 일찍 안 열림(시계 그대로)', () {
      final c = _controller();
      c.notifyMealCompleted('m1', _at(8, 5));
      final d = c.decideAt(_at(8, 12));
      // 식후약 시계창 [08:20,09:00]엔 아직 안 듦. 식사도 끝나 gap도 만료 → idle.
      expect(d.phase, MedPhase.idle);
    });
  });

  group('식후약(after) — 이벤트 모드 (afterMedUsesMealEvent=true)', () {
    test('식사 완료 시점부터 p2', () {
      final c = MedPhaseController(afterMedUsesMealEvent: true)
        ..setSchedule(_schedule);
      c.notifyMealCompleted('m1', _at(8, 5));
      final d = c.decideAt(_at(8, 12)); // 이벤트 창 [08:05, 08:35]
      expect(d.phase, MedPhase.p2);
      expect(d.targetId, 'd1');
    });
  });

  group('식사무관(none) — 시계 기반', () {
    test('약 time 근처 창 → p2 (식사 없이)', () {
      final c = _controller();
      final d = c.decideAt(_at(22, 5)); // [21:50, 22:30]
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

  group('공백기(gap)', () {
    test('뒤따르는 약 없는 식사 완료 직후 → gap', () {
      final c = _controller();
      c.notifyMealCompleted('m3', _at(15, 10));
      final d = c.decideAt(_at(15, 12)); // 완료 후 5분 이내, 겨냥 약 없음
      expect(d.phase, MedPhase.gap);
      expect(d.micActive, isTrue);
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
