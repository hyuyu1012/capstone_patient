import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/auth_service.dart';
import '../data/notification_service.dart';
import '../data/schedule_service.dart';
import '../models/patient.dart';
import '../models/schedule_item.dart';
import '../sensing/med_sensing_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The claimed patient's live schedule, read straight from the same Firestore
/// subcollection the guardian app writes to. This is the end-to-end proof:
/// what a guardian registers shows up here in real time.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final schedules = context.read<ScheduleService>();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _Header(patient: patient),
            Expanded(
              child: StreamBuilder<List<ScheduleItem>>(
                stream: schedules.schedulesFor(patient.id),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('일정을 불러오지 못했어요.\n${snap.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.statusNegative)),
                      ),
                    );
                  }
                  final items = snap.data ?? const [];
                  // Keep the daily voice reminders in sync with the live
                  // schedule. syncSchedules no-ops when the set is unchanged.
                  context.read<NotificationService>().syncSchedules(items);
                  // Feed the same live schedule to the YAMNet sensing engine so
                  // it knows when to open meal/medication monitoring windows.
                  context.read<MedSensingService>().setSchedule(items);
                  if (items.isEmpty) return const _Empty();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ScheduleTile(item: items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Text('오늘의 일정', style: AppType.pageTitle),
              const Spacer(),
              IconButton(
                tooltip: '로그아웃',
                onPressed: () {
                  context.read<NotificationService>().cancelAll();
                  context.read<AuthService>().signOut();
                },
                icon: const Icon(Icons.logout_rounded,
                    size: 20, color: AppColors.labelNeutral),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.avatarGradient,
                ),
                child: Text(patient.profileInitial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${patient.name} · ${patient.relation}',
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.labelStrong)),
                    const SizedBox(height: 2),
                    Text('보호자 ${patient.guardianIds.length}명과 연결됨',
                        style: AppType.settingsRowSub),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary08,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('코드 ${patient.inviteCode}',
                    style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)
                        .tabular),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final isMed = item.kind == ScheduleKind.med;
    // 보호자/센서팀이 복용·식사 완료를 기록하면 타일 전체를 은은한 파란색으로
    // 칠해 시각적으로 구분한다 (체크 아이콘 대신 색으로 표현).
    final isDone = item.taken;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone ? AppColors.primary04 : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                isDone ? AppColors.primary20 : AppColors.lineNormalNormal),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDone ? AppColors.primary : AppColors.primary08,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isMed ? Icons.medication_outlined : Icons.restaurant_outlined,
              size: 21,
              color: isDone ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.075,
                        color: AppColors.labelStrong)),
                const SizedBox(height: 3),
                Text(
                  [item.kind.label, if (item.dose != null) item.dose!]
                      .join(' · '),
                  style: AppType.rowSub,
                ),
              ],
            ),
          ),
          Text(
            isDone && item.takenAt != null ? item.takenAt! : item.time,
            style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDone
                        ? AppColors.primary78
                        : AppColors.labelStrong)
                .tabular,
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note_outlined,
                size: 48, color: AppColors.labelAlternative),
            const SizedBox(height: 12),
            const Text('아직 등록된 일정이 없어요',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.labelStrong)),
            const SizedBox(height: 6),
            Text('보호자가 앱에서 약·식사 일정을 등록하면\n여기에 실시간으로 나타나요.',
                textAlign: TextAlign.center,
                style: AppType.pageSubtitle.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }
}
