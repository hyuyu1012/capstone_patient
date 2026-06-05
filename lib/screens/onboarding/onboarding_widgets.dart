import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// The app's brand shield + check mark (Login/NewPatient logos). Two stroked
/// paths over a 24×24 viewBox.
class BrandShield extends StatelessWidget {
  const BrandShield({super.key, this.size = 32, this.color = Colors.white, this.strokeWidth = 1.8});

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ShieldPainter(color, strokeWidth)),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter(this.color, this.strokeWidth);
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Shield: M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6z
    final shield = Path()
      ..moveTo(12, 3)
      ..lineTo(4, 6)
      ..lineTo(4, 12)
      ..cubicTo(4, 17, 7.5, 20, 12, 21)
      ..cubicTo(16.5, 20, 20, 17, 20, 12)
      ..lineTo(20, 6)
      ..close();
    canvas.drawPath(shield, paint);
    // Check: M9 12.5l2.2 2.2L15.5 10
    canvas.drawPath(
      Path()
        ..moveTo(9, 12.5)
        ..lineTo(11.2, 14.7)
        ..lineTo(15.5, 10),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.color != color || old.strokeWidth != strokeWidth;
}

/// Onboarding top bar: a back chevron, with an optional trailing widget
/// (a "나중에" text button or a "1 / 3" step chip).
class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({super.key, this.onBack, this.trailing});

  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              tooltip: '뒤로',
              icon: const Icon(Icons.chevron_left_rounded, size: 24, color: AppColors.labelStrong),
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// A "1 / 3" step indicator chip.
class StepChip extends StatelessWidget {
  const StepChip({super.key, required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fillAlternative,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$step / $total',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.69, // 0.06em
          color: AppColors.labelAlternative,
        ).tabular,
      ),
    );
  }
}

/// Full-width 52px primary CTA with the design's disabled state + blue shadow.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.disabledLabel,
  });

  final String label;
  final String? disabledLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.fillNeutral,
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? const [BoxShadow(color: AppColors.primary18, blurRadius: 12, offset: Offset(0, 4))]
              : null,
        ),
        child: Text(
          enabled ? label : (disabledLabel ?? label),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.075, // -0.005em
            color: enabled ? Colors.white : AppColors.labelAlternative,
          ),
        ),
      ),
    );
  }
}

/// Field wrapper: a bold label (with required `*` or `· 선택`) over its input.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.optional = false,
  });

  final String label;
  final Widget child;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.12, // -0.008em
                color: AppColors.labelStrong,
              ),
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(text: ' *', style: TextStyle(color: AppColors.primary)),
                if (optional)
                  const TextSpan(
                    text: '  · 선택',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.labelAlternative,
                    ),
                  ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// A bordered text field that highlights its border + glow on focus, matching
/// the handoff inputs (50px tall, radius 12).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.lineNormalNormal,
        ),
        boxShadow: focused ? const [BoxShadow(color: AppColors.primary10, blurRadius: 0, spreadRadius: 3)] : null,
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        onChanged: widget.onChanged,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.labelStrong,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: InputBorder.none,
          hintText: widget.placeholder,
          hintStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.labelAlternative,
          ),
        ),
      ),
    );
  }
}

/// Equal-width segmented control (gender picker). Active segment is a white
/// pill with a soft shadow on a fill-alternative track.
class AppSegmentedControl extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<({String id, String label})> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.fillAlternative,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(options[i].id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == options[i].id ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: value == options[i].id
                        ? const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 6, offset: Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    options[i].label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value == options[i].id ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: -0.07,
                      color: value == options[i].id ? AppColors.labelStrong : AppColors.labelNeutral,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
