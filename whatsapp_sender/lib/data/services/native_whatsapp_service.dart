import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/message_formatter.dart';
import '../../core/utils/phone_formatter.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/contact.dart';
import '../../domain/entities/send_result.dart';
import '../../domain/services/whatsapp_sender_service.dart';

/// Implementação do serviço de envio via app WhatsApp nativo (Android/iOS).
/// Abre o WhatsApp instalado usando deep links (whatsapp://send).
final class NativeWhatsAppService implements WhatsAppSenderService {
  @override
  bool get requiresWebView => false;

  @override
  Stream<SendEvent> sendMessages({
    required List<Contact> contacts,
    required AppConfig config,
    required List<String> attachments,
    required bool Function() isCancelled,
  }) async* {
    final rng = math.Random();
    final total = contacts.length;
    final results = <SendResult>[];
    int i = 0;

    yield SendEventLog('Iniciando envio via WhatsApp nativo…', LogType.info);

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
        results.add(SendResult(
          name: name,
          originalPhone: phone,
          formattedPhone: '',
          status: 'ignorado',
          detail: 'telefone vazio',
          timestamp: DateTime.now(),
        ));
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

      // Abre o WhatsApp com deep link
      final uri = Uri.parse(
        'https://wa.me/$tel?text=${Uri.encodeComponent(message)}',
      );

      String status;
      String detail;

      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          status = 'enviado';
          detail = 'aberto no WhatsApp';
          yield SendEventLog('   Aberto no WhatsApp.', LogType.ok);
        } else {
          status = 'erro';
          detail = 'não foi possível abrir o WhatsApp';
          yield SendEventLog('   FALHA ao abrir WhatsApp.', LogType.error);
        }
      } catch (e) {
        status = 'erro';
        detail = 'erro: $e';
        yield SendEventLog('   ERRO: $e', LogType.error);
      }

      results.add(SendResult(
        name: name,
        originalPhone: phone,
        formattedPhone: tel,
        status: status,
        detail: detail,
        timestamp: DateTime.now(),
      ));
      yield SendEventContactStatus(contact.id, phone, status, detail);
      yield SendEventProgress(i, total);

      // Intervalo entre envios para dar tempo do usuário confirmar
      if (i < total && !isCancelled()) {
        final delay = config.intervalMin +
            rng.nextInt(
              (config.intervalMax - config.intervalMin).clamp(1, 999) + 1,
            );
        yield SendEventLog(
          '   Aguardando ${delay}s (volte ao app após enviar)…',
          LogType.info,
        );
        await Future.delayed(Duration(seconds: delay));
      }
    }

    // Salva log
    final logPath = await _saveLog(results);
    final sent = results.where((r) => r.status == 'enviado').length;
    final errors = results.where((r) => r.status == 'erro').length;
    final ignored = results.where((r) => r.status == 'ignorado').length;

    yield SendEventLog('═' * 46, LogType.info);
    yield SendEventLog('Enviados:  $sent', LogType.ok);
    if (errors > 0) yield SendEventLog('Erros:     $errors', LogType.error);
    if (ignored > 0) {
      yield SendEventLog('Ignorados: $ignored', LogType.warning);
    }
    yield SendEventLog('Log salvo: $logPath', LogType.info);

    yield SendEventFinished(sent, errors, ignored, logPath);
  }

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
        const JsonEncoder.withIndent('  ')
            .convert(results.map((r) => r.toJson()).toList()),
      );
      return file.path;
    } catch (_) {
      return '';
    }
  }
}
