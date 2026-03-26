import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/webview/app_webview_controller.dart';
import '../../core/utils/message_formatter.dart';
import '../../core/utils/phone_formatter.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/contact.dart';
import '../../domain/entities/send_result.dart';
import '../../domain/services/whatsapp_sender_service.dart';

/// CSS selectors — mesmos do app Python original.
const _kSelLoginOk =
    '#pane-side, [data-testid="chat-list"], div[aria-label="Lista de conversas"],'
    'div[aria-label="Conversation list"]';

const _kSelMsgBox = 'div[contenteditable="true"][data-tab="10"],'
    'div[contenteditable="true"][aria-label*="mensagem"],'
    'div[contenteditable="true"][aria-label*="message"],'
    'footer div[contenteditable="true"]';

/// Implementação do serviço de envio via WebView (Windows Desktop).
/// Ações são realizadas por navegação de URL e injeção de JavaScript.
final class WebViewWhatsAppService implements WhatsAppSenderService {
  WebViewWhatsAppService(this._controller);
  final AppWebViewController _controller;

  @override
  bool get requiresWebView => true;

  AppWebViewController get controller => _controller;

  // ─────────────────────────────────────────────────────────────────
  //  STREAM PRINCIPAL
  // ─────────────────────────────────────────────────────────────────
  @override
  Stream<SendEvent> sendMessages({
    required List<Contact> contacts,
    required AppConfig config,
    required List<String> attachments,
    required bool Function() isCancelled,
  }) async* {
    final controller = _controller;
    final rng = math.Random();

    // 1 ── abre WhatsApp Web e aguarda login ──────────────────────
    yield SendEventLoginRequired();
    await controller.loadUrl('https://web.whatsapp.com');

    yield SendEventLog(
      'Aguardando WhatsApp Web — escaneie o QR code se necessário…',
      LogType.warning,
    );

    final loggedIn = await _waitForSelector(
      controller,
      _kSelLoginOk,
      const Duration(seconds: 120),
    );

    if (!loggedIn) {
      yield SendEventLog(
        'Timeout no login. Feche e tente novamente.',
        LogType.error,
      );
      yield SendEventFinished(0, 0, 0, '');
      return;
    }

    yield SendEventLoggedIn();
    yield SendEventLog('WhatsApp Web conectado!', LogType.ok);

    // 2 ── loop de envios ──────────────────────────────────────────
    final total = contacts.length;
    final results = <SendResult>[];
    int i = 0;

    for (final contact in contacts) {
      if (isCancelled()) {
        yield SendEventLog('Envio interrompido pelo usuário.', LogType.warning);
        break;
      }

      i++;
      final name = contact.name.trim();
      final phone = contact.phone.trim();

      if (phone.isEmpty) {
        yield SendEventLog(
          '[$i/$total] IGNORADO (sem telefone): ${name.isEmpty ? "-" : name}',
          LogType.warning,
        );
        yield SendEventContactStatus(
          contact.id,
          phone,
          'ignorado',
          'telefone vazio',
        );
        yield SendEventProgress(i, total);
        results.add(
          SendResult(
            name: name,
            originalPhone: phone,
            formattedPhone: '',
            status: 'ignorado',
            detail: 'telefone vazio',
            timestamp: DateTime.now(),
          ),
        );
        continue;
      }

      final template = contact.individualMessage.isNotEmpty
          ? contact.individualMessage
          : config.defaultMessage;
      final message = MessageFormatter.format(template, {
        'nome': name,
        'telefone': phone,
        'name': name,
      });
      final tel = PhoneFormatter.format(phone);

      yield SendEventLog('[$i/$total] $name → $tel', LogType.info);

      // Envia texto ────────────────────────────────────────────────
      final textResult = await _sendText(
        controller,
        tel,
        message,
        config.pageTimeout,
      );
      String status = textResult ? 'enviado' : 'erro';
      String detail = textResult ? 'texto enviado' : 'falha ao enviar texto';

      if (textResult) {
        yield SendEventLog('   Texto enviado.', LogType.ok);
      } else {
        yield SendEventLog('   FALHA ao enviar texto.', LogType.error);
      }

      // Envia arquivos ─────────────────────────────────────────────
      if (textResult && attachments.isNotEmpty) {
        for (int j = 0; j < attachments.length; j++) {
          if (isCancelled()) break;
          final arq = attachments[j];
          if (!File(arq).existsSync()) {
            yield SendEventLog(
              '   Arquivo ${j + 1} não encontrado.',
              LogType.warning,
            );
            continue;
          }
          final fileOk = await _sendFile(controller, arq, config.pageTimeout);
          if (fileOk) {
            yield SendEventLog(
              '   Arquivo ${j + 1} (${p.basename(arq)}) enviado.',
              LogType.ok,
            );
            detail += ' | arq${j + 1} ok';
          } else {
            yield SendEventLog(
              '   Arquivo ${j + 1} (${p.basename(arq)}) falhou.',
              LogType.warning,
            );
          }
        }
      }

      results.add(
        SendResult(
          name: name,
          originalPhone: phone,
          formattedPhone: tel,
          status: status,
          detail: detail,
          timestamp: DateTime.now(),
        ),
      );
      yield SendEventContactStatus(contact.id, phone, status, detail);
      yield SendEventProgress(i, total);

      // Intervalo anti-bloqueio ─────────────────────────────────────
      if (i < total && !isCancelled()) {
        final delay = config.intervalMin +
            rng.nextInt(
              (config.intervalMax - config.intervalMin).clamp(1, 999) + 1,
            );
        yield SendEventLog('   Aguardando ${delay}s…', LogType.info);
        await Future.delayed(Duration(seconds: delay));
      }
    }

    // 3 ── salva log ───────────────────────────────────────────────
    final logPath = await _saveLog(results);

    final sent = results.where((r) => r.status == 'enviado').length;
    final errors = results.where((r) => r.status == 'erro').length;
    final ignored = results.where((r) => r.status == 'ignorado').length;

    yield SendEventLog('═' * 46, LogType.info);
    yield SendEventLog('Enviados:  $sent', LogType.ok);
    if (errors > 0) yield SendEventLog('Erros:     $errors', LogType.error);
    if (ignored > 0) yield SendEventLog('Ignorados: $ignored', LogType.warning);
    yield SendEventLog('Log salvo: $logPath', LogType.info);

    yield SendEventFinished(sent, errors, ignored, logPath);
  }

  // ─────────────────────────────────────────────────────────────────
  //  ENVIAR TEXTO
  // ─────────────────────────────────────────────────────────────────
  Future<bool> _sendText(
    AppWebViewController ctrl,
    String tel,
    String message,
    int timeout,
  ) async {
    final encoded = Uri.encodeComponent(message);
    final url = 'https://web.whatsapp.com/send?phone=$tel&text=$encoded';

    await ctrl.loadUrl(url);

    // Aguarda caixa de mensagem aparecer
    final boxFound = await _waitForSelector(
      ctrl,
      _kSelMsgBox,
      Duration(seconds: timeout),
    );
    if (!boxFound) return false;

    await Future.delayed(const Duration(milliseconds: 1500));

    // Tenta clicar no botão send via CSS selectors
    final sendSelectors = [
      'span[data-icon="send"]',
      '[data-testid="send"]',
      'div[aria-label="Enviar"]',
      'div[aria-label="Send"]',
      'button[aria-label="Send"]',
    ];

    for (final sel in sendSelectors) {
      final clicked = await ctrl.executeJavaScript('''
        (function() {
          var el = document.querySelector(${jsonEncode(sel)});
          if (el) { el.click(); return true; }
          return false;
        })()
      ''');
      if (clicked.toString() == 'true') {
        await Future.delayed(const Duration(seconds: 2));
        return true;
      }
    }

    // Fallback: pressiona Enter no campo de texto
    final enterOk = await ctrl.executeJavaScript('''
      (function() {
        var sels = [
          'div[contenteditable="true"][data-tab="10"]',
          'footer div[contenteditable="true"]'
        ];
        for (var s of sels) {
          var el = document.querySelector(s);
          if (el) {
            el.focus();
            var opts = {key:'Enter', code:'Enter', keyCode:13, which:13, bubbles:true};
            el.dispatchEvent(new KeyboardEvent('keydown', opts));
            el.dispatchEvent(new KeyboardEvent('keypress', opts));
            el.dispatchEvent(new KeyboardEvent('keyup', opts));
            return true;
          }
        }
        return false;
      })()
    ''');

    if (enterOk.toString() == 'true') {
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }

    return false;
  }

  // ─────────────────────────────────────────────────────────────────
  //  ENVIAR ARQUIVO (via base64 → JS File API)
  // ─────────────────────────────────────────────────────────────────
  Future<bool> _sendFile(
    AppWebViewController ctrl,
    String filePath,
    int timeout,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      final fileName = p.basename(filePath);
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

      // Clica no botão de annexo
      final attachSelectors = [
        'span[data-icon="attach-menu-plus"]',
        'span[data-icon="plus"]',
        'div[title="Attach"]',
        'span[data-icon="clip"]',
      ];

      bool attachClicked = false;
      for (final sel in attachSelectors) {
        final r = await ctrl.executeJavaScript('''
          (function() {
            var el = document.querySelector(${jsonEncode(sel)});
            if (el) { el.click(); return true; }
            return false;
          })()
        ''');
        if (r.toString() == 'true') {
          attachClicked = true;
          break;
        }
      }
      if (!attachClicked) return false;

      await Future.delayed(const Duration(milliseconds: 900));

      // Injeta arquivo via DataTransfer API
      final fileSet = await ctrl.executeJavaScript('''
        (function(b64, name, mime) {
          try {
            var binary = atob(b64);
            var bytes = new Uint8Array(binary.length);
            for (var i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
            var file = new File([bytes], name, {type: mime});
            var dt = new DataTransfer();
            dt.items.add(file);
            var inputs = document.querySelectorAll('input[type="file"]');
            for (var inp of inputs) {
              try {
                Object.defineProperty(inp, 'files', {value: dt.files, configurable: true});
                inp.dispatchEvent(new Event('change', {bubbles: true}));
                return true;
              } catch(e) {}
            }
            return false;
          } catch(e) { return false; }
        })(${jsonEncode(b64)}, ${jsonEncode(fileName)}, ${jsonEncode(mimeType)})
      ''');

      if (fileSet.toString() != 'true') return false;

      await Future.delayed(const Duration(seconds: 2));

      // Clica no botão de envio do arquivo
      final sendSelectors = [
        'span[data-icon="send"]',
        'div[aria-label="Enviar"]',
        '[data-testid="send"]',
      ];
      for (final sel in sendSelectors) {
        final r = await ctrl.executeJavaScript('''
          (function() {
            var el = document.querySelector(${jsonEncode(sel)});
            if (el) { el.click(); return true; }
            return false;
          })()
        ''');
        if (r.toString() == 'true') {
          await Future.delayed(const Duration(seconds: 2));
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────────

  /// Faz polling de um seletor CSS até aparecer ou timeout.
  Future<bool> _waitForSelector(
    AppWebViewController ctrl,
    String selector,
    Duration timeout,
  ) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      try {
        final r = await ctrl.executeJavaScript(
          'Boolean(document.querySelector(${jsonEncode(selector)}))',
        );
        if (r.toString() == 'true') return true;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 600));
    }
    return false;
  }

  /// Salva o log de envios em JSON no diretório de suporte da app.
  Future<String> _saveLog(List<SendResult> results) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceAll('T', '_')
          .substring(0, 15);
      final file = File('${dir.path}/log_$ts.json');
      await file.writeAsString(
        const JsonEncoder.withIndent(
          '  ',
        ).convert(results.map((r) => r.toJson()).toList()),
      );
      return file.path;
    } catch (_) {
      return '';
    }
  }
}
