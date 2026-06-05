import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/auth_service.dart';
import '../data/patient_link_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'onboarding/onboarding_widgets.dart';

/// Patient enters the 6-char invite code the guardian generated. On success the
/// patient doc's `userId` is set to this account and AuthGate swaps to the
/// schedule view. Mirrors the guardian app's ConnectCodeScreen styling.
class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _busy = false;

  bool get _valid => _controllers.every((c) => c.text.isNotEmpty);
  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int i, String v) {
    final ch = v.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    _controllers[i].text = ch.isEmpty ? '' : ch.characters.last;
    _controllers[i].selection =
        TextSelection.collapsed(offset: _controllers[i].text.length);
    if (_controllers[i].text.isNotEmpty && i < 5) {
      _focusNodes[i + 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _submit() async {
    final user = context.read<AuthService>().currentUser;
    if (!_valid || _busy || user == null) return;
    setState(() => _busy = true);
    try {
      await context.read<PatientLinkService>().claimByInviteCode(
            code: _code,
            patientUid: user.uid,
          );
      // AuthGate's myPatient stream picks up the claim and routes onward.
    } on PatientLinkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('연결 실패: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — logout instead of a back chevron (this is the root).
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.read<AuthService>().signOut(),
                    icon: const Icon(Icons.logout_rounded,
                        size: 16, color: AppColors.labelNeutral),
                    label: const Text('로그아웃',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.labelNeutral)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.link_rounded,
                                size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'STEP 1 · 가족과 연결',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.72,
                              color: AppColors.labelNeutral,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '초대 코드를 입력하세요',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.528,
                          height: 1.3,
                          color: AppColors.labelStrong,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '보호자에게서 받은 6자리 코드를 입력하면\n보호자가 등록한 일정을 볼 수 있어요.',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: AppColors.labelNeutral,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [for (var i = 0; i < 6; i++) _codeCell(i)],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.labelNeutral),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '코드는 보호자 앱 → 설정 → 보호자 연결에서 확인할 수 있어요',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                                color: AppColors.labelNeutral,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: _busy ? '연결 중…' : '환자와 연결',
                        enabled: _valid && !_busy,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _codeCell(int i) {
    final filled = _controllers[i].text.isNotEmpty;
    return SizedBox(
      width: 44,
      height: 56,
      child: TextField(
        controller: _controllers[i],
        focusNode: _focusNodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.characters,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]'))
        ],
        onChanged: (v) => _onChanged(i, v),
        style: const TextStyle(
          fontFamily: AppType.family,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.labelStrong,
        ),
        decoration: InputDecoration(
          counterText: '',
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: filled ? AppColors.primary : AppColors.lineNormalNormal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
