import 'package:flutter/material.dart';
import 'package:task_tracker/utils/app_colors.dart';

class GradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const GradientText(
    this.text, {
    super.key,
    Gradient? gradient,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : gradient = gradient ??
            const LinearGradient(

              colors: [AppColors.primaryColor, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }
}
