import 'package:flutter/material.dart';

class HoverWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? hoverColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? elevation;

  const HoverWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.hoverColor,
    this.borderRadius,
    this.padding,
    this.elevation,
  });

  @override
  State<HoverWrapper> createState() => _HoverWrapperState();
}

class _HoverWrapperState extends State<HoverWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered ? (widget.hoverColor ?? Colors.grey.withAlpha(25)) : Colors.transparent,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          boxShadow: _isHovered && widget.elevation != null
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: widget.elevation!,
                    offset: Offset(0, widget.elevation! / 2),
                  ),
                ]
              : null,
        ),
        padding: widget.padding,
        child: GestureDetector(
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}
