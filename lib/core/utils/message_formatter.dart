/// Interpola variáveis {nome}, {telefone} etc. no template da mensagem.
abstract final class MessageFormatter {
  MessageFormatter._();

  static String format(String template, Map<String, dynamic> variables) {
    try {
      var result = template;
      for (final entry in variables.entries) {
        result = result.replaceAll('{${entry.key}}', '${entry.value}');
      }
      return result;
    } catch (_) {
      return template;
    }
  }
}
