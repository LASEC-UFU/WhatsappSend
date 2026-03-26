/// Resultado de um envio individual — gravado no log JSON.
class SendResult {
  const SendResult({
    required this.name,
    required this.originalPhone,
    required this.formattedPhone,
    required this.status,
    required this.detail,
    required this.timestamp,
  });

  final String name;
  final String originalPhone;
  final String formattedPhone;
  final String status; // 'enviado' | 'erro' | 'ignorado'
  final String detail;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'nome': name,
    'telefone_original': originalPhone,
    'telefone_formatado': formattedPhone,
    'status': status,
    'detalhe': detail,
    'horario': timestamp.toIso8601String(),
  };
}

/// Evento emitido pelo serviço de envio para atualizar a UI.
sealed class SendEvent {}

class SendEventLog extends SendEvent {
  SendEventLog(this.message, this.type);
  final String message;
  final LogType type;
}

class SendEventProgress extends SendEvent {
  SendEventProgress(this.current, this.total);
  final int current;
  final int total;
}

class SendEventContactStatus extends SendEvent {
  SendEventContactStatus(this.contactId, this.phone, this.status, this.detail);
  final String contactId;
  final String phone;
  final String status;
  final String detail;
}

class SendEventFinished extends SendEvent {
  SendEventFinished(this.sent, this.errors, this.ignored, this.logPath);
  final int sent;
  final int errors;
  final int ignored;
  final String logPath;
}

class SendEventLoginRequired extends SendEvent {}

class SendEventLoggedIn extends SendEvent {}

enum LogType { info, ok, error, warning }
