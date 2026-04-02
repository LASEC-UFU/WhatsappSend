import 'package:uuid/uuid.dart';

enum SendStatus { pending, sending, sent, error, ignored }

/// Entidade de contato — imutável nas propriedades principais.
class Contact {
  Contact({
    String? id,
    required this.name,
    required this.phone,
    this.individualMessage = '',
    this.status = SendStatus.pending,
    this.statusDetail = '',
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String name;
  final String phone;
  final String individualMessage;
  SendStatus status;
  String statusDetail;

  Contact copyWith({
    String? name,
    String? phone,
    String? individualMessage,
    SendStatus? status,
    String? statusDetail,
  }) => Contact(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    individualMessage: individualMessage ?? this.individualMessage,
    status: status ?? this.status,
    statusDetail: statusDetail ?? this.statusDetail,
  );

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String?,
    name: (json['nome'] as String?) ?? (json['name'] as String?) ?? '',
    phone: '${json['telefone'] ?? json['phone'] ?? ''}',
    individualMessage:
        (json['mensagem'] as String?) ?? (json['message'] as String?) ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': name,
    'telefone': phone,
    'mensagem': individualMessage,
  };
}
