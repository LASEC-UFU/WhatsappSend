import 'package:flutter/material.dart';

/// Paleta de cores do WhatsApp Sender — mesma do app Python original.
abstract final class AppColors {
  // Verde WhatsApp
  static const Color waGreen = Color(0xFF25D366);
  static const Color waDarkGreen = Color(0xFF075E54);
  static const Color waMidGreen = Color(0xFF128C7E);
  static const Color waHoverGreen = Color(0xFF1DA851);
  static const Color waPressedGreen = Color(0xFF179C47);
  static const Color waBubble = Color(0xFFDCF8C6);

  // Cinzas / fundos
  static const Color background = Color(0xFFF0F2F5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color neutralBtn = Color(0xFF607D8B);
  static const Color neutralBtnHover = Color(0xFF546E7A);
  static const Color neutralBtnPressed = Color(0xFF455A64);

  // Vermelho / erros
  static const Color red = Color(0xFFE53935);
  static const Color redHover = Color(0xFFC62828);
  static const Color redPressed = Color(0xFFB71C1C);
  static const Color redBubble = Color(0xFFFFCDD2);

  // Laranja / avisos
  static const Color orange = Color(0xFFF57C00);
  static const Color orangeBubble = Color(0xFFFFF9C4);

  // Azul / ações secundárias
  static const Color blue = Color(0xFF1565C0);
  static const Color blueHover = Color(0xFF1976D2);

  // Utilitários
  static const Color white = Color(0xFFFFFFFF);
  static const Color logBg = Color(0xFF1E2A1E);
  static const Color logText = Color(0xFFC8F0DC);
  static const Color logOk = Color(0xFF69F0AE);
  static const Color logError = Color(0xFFFF5252);
  static const Color logInfo = Color(0xFF82B1FF);
  static const Color logWarning = Color(0xFFFFD740);
}
