import 'package:capstone_patient/sensing/meal_state_machine.dart';
import 'package:capstone_patient/sensing/med_result_writer.dart' show MealStatus;
import 'package:flutter_test/flutter_test.dart';

DateTime _at(int h, int m, [int s = 0]) => DateTime(2026, 6, 5, h, m, s);

void main() {
  group('식사 상태머신', () {
    test('초기 상태는 notEaten', () {
      expect(MealStateMachine().status, MealStatus.notEaten);
    });

    test('씹기가 kMinChews 미만이면 아직 notEaten', () {
      final m = MealStateMachine();
      m.onChew(_at(8, 0));
      m.onChew(_at(8, 0, 1));
      expect(m.status, MealStatus.notEaten, reason: '2회는 임계(3) 미만');
    });

    test('씹기 3회 이상 → inProgress', () {
      final m = MealStateMachine();
      m.onChew(_at(8, 0));
      m.onChew(_at(8, 0, 1));
      m.onChew(_at(8, 0, 2));
      expect(m.status, MealStatus.inProgress);
    });

    test('마지막 씹기 후 3분 무음 → eaten (tick true 한 번만)', () {
      final m = MealStateMachine();
      for (var i = 0; i < 3; i++) {
        m.onChew(_at(8, 0, i));
      }
      // 2분 경과: 아직 식사 중
      expect(m.tick(_at(8, 2, 2)), isFalse);
      expect(m.status, MealStatus.inProgress);
      // 3분 경과: 완료
      expect(m.tick(_at(8, 3, 3)), isTrue);
      expect(m.status, MealStatus.eaten);
      // 다시 tick해도 중복 발사 없음
      expect(m.tick(_at(8, 4, 0)), isFalse);
    });

    test('eaten 후 추가 씹기는 무시 (재시작 안 함)', () {
      final m = MealStateMachine();
      for (var i = 0; i < 3; i++) {
        m.onChew(_at(8, 0, i));
      }
      m.tick(_at(8, 3, 3)); // eaten
      m.onChew(_at(8, 5, 0));
      expect(m.status, MealStatus.eaten);
    });

    test('식사 중 창 닫힘 → finalizeOnExit가 eaten으로 마무리', () {
      final m = MealStateMachine();
      for (var i = 0; i < 3; i++) {
        m.onChew(_at(8, 0, i));
      }
      expect(m.status, MealStatus.inProgress);
      expect(m.finalizeOnExit(), isTrue);
      expect(m.status, MealStatus.eaten);
    });

    test('식사 안 한 채 창 닫힘 → finalizeOnExit false', () {
      final m = MealStateMachine();
      m.onChew(_at(8, 0)); // 1회뿐 → notEaten
      expect(m.finalizeOnExit(), isFalse);
    });

    test('reset 후 새 식사 세션', () {
      final m = MealStateMachine();
      for (var i = 0; i < 3; i++) {
        m.onChew(_at(8, 0, i));
      }
      m.finalizeOnExit();
      m.reset();
      expect(m.status, MealStatus.notEaten);
    });
  });
}
