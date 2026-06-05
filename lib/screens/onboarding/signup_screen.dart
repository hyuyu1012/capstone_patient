import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../theme/app_colors.dart';
import 'onboarding_widgets.dart';

/// Email sign-up. Creates a Firebase Auth user + `users/{uid}` doc; AuthGate
/// then swaps to BranchScreen on the next auth-state tick.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;

  bool get _valid => _email.text.contains('@') && _pw.text.length >= 6;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthService>().signUp(
            email: _email.text,
            password: _pw.text,
          );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingTopBar(onBack: () => Navigator.pop(context)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '회원가입',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.528,
                                height: 1.25,
                                color: AppColors.labelStrong,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '가입할 이메일과 비밀번호를 입력하세요.',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                                color: AppColors.labelNeutral,
                              ),
                            ),
                            const SizedBox(height: 28),
                            LabeledField(
                              label: '이메일',
                              child: AppTextField(
                                controller: _email,
                                placeholder: 'name@example.com',
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 12),
                            LabeledField(
                              label: '비밀번호',
                              child: AppTextField(
                                controller: _pw,
                                placeholder: '6자 이상',
                                obscureText: true,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const Spacer(),
                            PrimaryButton(
                              label: _busy ? '가입 중…' : '회원가입',
                              enabled: _valid && !_busy,
                              onPressed: _submit,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '이미 계정이 있으신가요? ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.labelNeutral,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        '로그인',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
