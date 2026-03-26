import '../entities/app_config.dart';
import '../entities/contact.dart';
import '../entities/send_result.dart';

/// Contrato do serviço de automação WhatsApp — Interface Segregation.
abstract interface class WhatsAppSenderService {
  /// Retorna um Stream de eventos de envio.
  Stream<SendEvent> sendMessages({
    required List<Contact> contacts,
    required AppConfig config,
    required List<String> attachments,
    required bool Function() isCancelled,
  });

  /// Se true, este serviço precisa de WebView na UI.
  bool get requiresWebView;
}
