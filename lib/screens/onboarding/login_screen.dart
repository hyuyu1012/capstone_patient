import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'email_login_screen.dart';
import 'onboarding_widgets.dart';

/// First screen — same brand layout as the guardian app's login. The patient
/// flow needs a real account for the invite-code claim, so social buttons are
/// placeholders that nudge to email; 이메일로 시작하기 opens the real sign-in.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _next(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('소셜 로그인은 준비 중이에요. 이메일로 시작해주세요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Brand area
            const Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, 32, 28, 16),
                child: Center(child: _BrandMark()),
              ),
            ),
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Column(
                children: [
                  _AuthButton(
                    background: AppColors.kakaoYellow,
                    foreground: AppColors.kakaoText,
                    icon: const _KakaoLogo(),
                    label: '카카오로 시작하기',
                    onTap: () => _next(context),
                  ),
                  const SizedBox(height: 10),
                  _AuthButton(
                    background: Colors.white,
                    foreground: AppColors.labelStrong,
                    border: const BorderSide(color: AppColors.lineNormalNormal),
                    icon: const _GoogleLogo(),
                    label: 'Google로 시작하기',
                    onTap: () => _next(context),
                  ),
                  const SizedBox(height: 10),
                  _AuthButton(
                    background: Colors.black,
                    foreground: Colors.white,
                    icon: const Icon(Icons.apple, size: 20, color: Colors.white),
                    label: 'Apple로 시작하기',
                    onTap: () => _next(context),
                  ),
                  const _OrDivider(),
                  _AuthButton(
                    background: AppColors.primary,
                    foreground: Colors.white,
                    icon: const Icon(Icons.mail_outline_rounded, size: 19, color: Colors.white),
                    label: '이메일로 시작하기',
                    primary: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
                    ),
                  ),
                ],
              ),
            ),
            // Footer terms
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: _TermsText(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 102, 255, 0.22), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: const Center(child: BrandShield(size: 32)),
        ),
        const SizedBox(height: 18),
        const Text(
          '안심 케어',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.572, // -0.022em
            height: 1.2,
            color: AppColors.labelStrong,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '오늘의 약과 식사를 챙겨드려요.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: AppColors.labelNeutral,
          ),
        ),
      ],
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
    required this.onTap,
    this.border,
    this.primary = false,
  });

  final Color background;
  final Color foreground;
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final BorderSide? border;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: border == null ? null : Border.fromBorderSide(border!),
          boxShadow: primary
              ? const [BoxShadow(color: AppColors.primary18, blurRadius: 12, offset: Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, child: Center(child: icon)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.075,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, color: AppColors.lineNormalNeutral)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '또는',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.66, // 0.06em
                color: AppColors.labelAlternative,
              ),
            ),
          ),
          Expanded(child: Divider(height: 1, color: AppColors.lineNormalNeutral)),
        ],
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    const emphasis = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.55,
      color: AppColors.labelNeutral,
    );
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.55,
          color: AppColors.labelAlternative,
        ),
        children: [
          TextSpan(text: '계속 진행 시 '),
          TextSpan(text: '이용약관', style: emphasis),
          TextSpan(text: ' 및 '),
          TextSpan(text: '개인정보 처리방침', style: emphasis),
          TextSpan(text: '에 동의합니다.'),
        ],
      ),
    );
  }
}

// ── Brand logos (inline SVG ports) ───────────────────────────────────
class _KakaoLogo extends StatelessWidget {
  const _KakaoLogo();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(painter: _KakaoPainter()),
      );
}

class _KakaoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final p = Path()
      ..moveTo(12, 4.5)
      ..cubicTo(7.03, 4.5, 3, 7.65, 3, 11.55)
      ..cubicTo(3, 13.98, 4.6, 16.11, 7.03, 17.38)
      ..lineTo(6.2, 20.41)
      ..cubicTo(6.12, 20.68, 6.43, 20.9, 6.67, 20.75)
      ..lineTo(10.33, 18.35)
      ..cubicTo(10.88, 18.42, 11.43, 18.46, 12, 18.46)
      ..cubicTo(16.97, 18.46, 21, 15.31, 21, 11.42)
      ..cubicTo(21, 7.53, 16.97, 4.5, 12, 4.5)
      ..close();
    canvas.drawPath(p, Paint()..color = AppColors.kakaoText);
  }

  @override
  bool shouldRepaint(_KakaoPainter old) => false;
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(painter: _GooglePainter()),
      );
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    void fill(String _, Color c, Path path) => canvas.drawPath(path, Paint()..color = c);
    fill('blue', const Color(0xFF4285F4), Path()
      ..moveTo(21.6, 12.23)
      ..cubicTo(21.6, 11.49, 21.53, 10.78, 21.41, 10.10)
      ..lineTo(12, 10.10)
      ..lineTo(12, 14.13)
      ..lineTo(17.39, 14.13)
      ..cubicTo(17.16, 15.37, 16.45, 16.42, 15.39, 17.13)
      ..lineTo(15.39, 19.63)
      ..lineTo(18.62, 19.63)
      ..cubicTo(20.51, 17.89, 21.6, 15.33, 21.6, 12.23)
      ..close());
    fill('green', const Color(0xFF34A853), Path()
      ..moveTo(12, 22)
      ..cubicTo(14.7, 22, 16.96, 21.1, 18.62, 19.58)
      ..lineTo(15.39, 17.08)
      ..cubicTo(14.49, 17.68, 13.35, 18.04, 12, 18.04)
      ..cubicTo(9.4, 18.04, 7.19, 16.28, 6.4, 13.92)
      ..lineTo(3.06, 13.92)
      ..lineTo(3.06, 16.5)
      ..cubicTo(4.71, 19.78, 8.09, 22, 12, 22)
      ..close());
    fill('yellow', const Color(0xFFFBBC05), Path()
      ..moveTo(6.4, 13.92)
      ..cubicTo(6.2, 13.32, 6.08, 12.67, 6.08, 12)
      ..cubicTo(6.08, 11.33, 6.2, 10.68, 6.4, 10.08)
      ..lineTo(6.4, 7.5)
      ..lineTo(3.06, 7.5)
      ..cubicTo(2.39, 8.86, 2, 10.39, 2, 12)
      ..cubicTo(2, 13.61, 2.39, 15.14, 3.06, 16.5)
      ..lineTo(6.4, 13.92)
      ..close());
    fill('red', const Color(0xFFEA4335), Path()
      ..moveTo(12, 5.96)
      ..cubicTo(13.47, 5.96, 14.79, 6.46, 15.83, 7.46)
      ..lineTo(18.69, 4.6)
      ..cubicTo(16.95, 2.99, 14.7, 2, 12, 2)
      ..cubicTo(8.09, 2, 4.71, 4.22, 3.06, 7.5)
      ..lineTo(6.4, 10.08)
      ..cubicTo(7.19, 7.72, 9.4, 5.96, 12, 5.96)
      ..close());
  }

  @override
  bool shouldRepaint(_GooglePainter old) => false;
}
