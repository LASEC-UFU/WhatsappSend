import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../../core/webview/app_webview_controller.dart';
import '../../core/webview/webview_factory.dart';
import '../../data/services/native_whatsapp_service.dart';
import '../../data/services/webview_whatsapp_service.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/contact.dart';
import '../../domain/entities/send_result.dart';
import '../../domain/services/whatsapp_sender_service.dart';

/// Modo de envio disponível no Android.
enum SendMode {
  /// Automático via WhatsApp Web (WebView). Exige vincular uma vez.
  webView,

  /// Abre cada contato no WhatsApp instalado (manual, um a um).
  native,
}

class LogEntry {
  const LogEntry(this.message, this.type, this.time);
  final String message;
  final LogType type;
  final DateTime time;
}

/// Gerencia o estado do processo de envio e o WebViewController compartilhado.
final class SendProvider extends ChangeNotifier {
  SendProvider._(this._service, this._webViewController, this._sendMode);

  WhatsAppSenderService _service;
  AppWebViewController? _webViewController;
  SendMode _sendMode;

  /// Retorna o controller do WebView (nulo no modo nativo).
  AppWebViewController? get webViewController => _webViewController;

  /// Indica se o serviço ativo usa WebView.
  bool get requiresWebView => _service.requiresWebView;

  /// Modo de envio atual.
  SendMode get sendMode => _sendMode;

  /// Verdadeiro se a plataforma suporta escolha de modo (Android/iOS).
  bool get canSwitchMode => Platform.isAndroid || Platform.isIOS;

  bool _isSending = false;
  bool _cancelRequested = false;
  bool _showWebView = true;
  bool _loginRequired = false;
  bool _loggedIn = false;
  bool _switchingMode = false;

  int _progress = 0;
  int _total = 0;

  final List<LogEntry> _log = [];

  bool get isSending => _isSending;
  bool get showWebView => _showWebView;
  bool get loginRequired => _loginRequired;
  bool get loggedIn => _loggedIn;
  bool get switchingMode => _switchingMode;
  int get progress => _progress;
  int get total => _total;
  List<LogEntry> get log => List.unmodifiable(_log);

  double get progressPct => _total == 0 ? 0 : _progress / _total;

  set showWebView(bool v) {
    _showWebView = v;
    notifyListeners();
  }

  // ── Troca de modo (só Android) ────────────────────────────────────

  Future<void> switchMode(SendMode mode) async {
    if (mode == _sendMode || _isSending) return;
    _switchingMode = true;
    notifyListeners();

    // Descarta WebView antigo se havia
    _webViewController?.dispose();
    _webViewController = null;

    if (mode == SendMode.webView) {
      final ctrl = createWebViewController();
      await ctrl.initialize();
      _webViewController = ctrl;
      _service = WebViewWhatsAppService(ctrl);
    } else {
      _service = NativeWhatsAppService();
    }

    _sendMode = mode;
    _loginRequired = false;
    _loggedIn = false;
    _switchingMode = false;
    notifyListeners();
  }

  // ── Envio ─────────────────────────────────────────────────────────

  Future<void> startSend({
    required List<Contact> contacts,
    required AppConfig config,
    required List<String> attachments,
    required void Function(
      String id,
      String phone,
      String status,
      String detail,
    )
    onContactStatus,
    required VoidCallback onFinished,
  }) async {
    _isSending = true;
    _cancelRequested = false;
    _loginRequired = false;
    _loggedIn = false;
    _progress = 0;
    _total = contacts.length;
    _showWebView = true;
    notifyListeners();

    final stream = _service.sendMessages(
      contacts: contacts,
      config: config,
      attachments: attachments,
      isCancelled: () => _cancelRequested,
    );

    await for (final event in stream) {
      switch (event) {
        case SendEventLog(:final message, :final type):
          _log.add(LogEntry(message, type, DateTime.now()));
          notifyListeners();

        case SendEventProgress(:final current, :final total):
          _progress = current;
          _total = total;
          notifyListeners();

        case SendEventContactStatus(
          :final contactId,
          :final phone,
          :final status,
          :final detail,
        ):
          onContactStatus(contactId, phone, status, detail);

        case SendEventLoginRequired():
          _loginRequired = true;
          _showWebView = true;
          notifyListeners();

        case SendEventLoggedIn():
          _loggedIn = true;
          notifyListeners();

        case SendEventFinished():
          _isSending = false;
          notifyListeners();
          onFinished();
      }
    }

    _isSending = false;
    notifyListeners();
  }

  void cancel() {
    _cancelRequested = true;
  }

  void clearLog() {
    _log.clear();
    notifyListeners();
  }

  // ── Factory ───────────────────────────────────────────────────────

  static Future<SendProvider> build() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Android inicia no modo nativo por padrão;
      // o usuário pode trocar para WebView (automático) na tela de envio.
      return SendProvider._(NativeWhatsAppService(), null, SendMode.native);
    }
    final ctrl = createWebViewController();
    await ctrl.initialize();
    return SendProvider._(WebViewWhatsAppService(ctrl), ctrl, SendMode.webView);
  }
}
