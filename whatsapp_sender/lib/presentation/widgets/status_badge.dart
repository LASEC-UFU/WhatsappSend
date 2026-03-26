import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/contact.dart';

/// Badge colorido que representa o status de envio de um contato.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final SendStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      SendStatus.sent => (
        '✓ enviado',
        AppColors.waBubble,
        const Color(0xFF1B5E20),
      ),
      SendStatus.error => ('✗ erro', AppColors.redBubble, AppColors.redPressed),
      SendStatus.ignored => (
        '– ignorado',
        AppColors.orangeBubble,
        const Color(0xFFE65100),
      ),
      SendStatus.sending => (
        'enviando…',
        const Color(0xFFE3F2FD),
        AppColors.blue,
      ),
      SendStatus.pending => ('', Colors.transparent, Colors.transparent),
    };

    if (status == SendStatus.pending) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
