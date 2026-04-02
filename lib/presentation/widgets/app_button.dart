import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Botão estilizado com cantos arredondados e efeito hover/pressed.
/// Equivalente ao RoundedButton do app Python.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.waGreen,
    this.hoverColor = AppColors.waHoverGreen,
    this.pressedColor = AppColors.waPressedGreen,
    this.textColor = AppColors.white,
    this.height = 36,
    this.minWidth = 120,
    this.radius = 18,
    this.fontSize = 13,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color hoverColor;
  final Color pressedColor;
  final Color textColor;
  final double height;
  final double minWidth;
  final double radius;
  final double fontSize;
  final bool disabled;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (widget.disabled) {
      bg = const Color(0xFFB0BEC5);
    } else if (_pressed) {
      bg = widget.pressedColor;
    } else if (_hovered) {
      bg = widget.hoverColor;
    } else {
      bg = widget.color;
    }

    return MouseRegion(
      cursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: widget.disabled
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              },
        onTapCancel: () => setState(() => _pressed = false),
        child: UnconstrainedBox(
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          constraints: BoxConstraints(
            minWidth: widget.minWidth,
            minHeight: widget.height,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: widget.disabled
                      ? const Color(0xFFECEFF1)
                      : widget.textColor,
                  size: widget.fontSize + 2,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.disabled
                      ? const Color(0xFFECEFF1)
                      : widget.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.fontSize,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
