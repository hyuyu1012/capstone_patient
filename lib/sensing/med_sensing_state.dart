import 'medication_scorer.dart' show MedPhase;

/// UI/디버그용 현재 감지 상태 스냅샷. (web/native 공통 — 순수 Dart라 웹 안전)
class MedSensingState {
  final MedPhase phase;
  final String? targetId;
  final bool listening; // 마이크 가동 중인가
  final int score; // 현재 누적 복약 점수
  final String reason;

  const MedSensingState({
    required this.phase,
    required this.targetId,
    required this.listening,
    required this.score,
    required this.reason,
  });

  static const idle = MedSensingState(
    phase: MedPhase.idle,
    targetId: null,
    listening: false,
    score: 0,
    reason: '대기',
  );
}
