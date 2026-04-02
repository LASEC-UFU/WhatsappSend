import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/contact.dart';
import '../../domain/repositories/contact_repository.dart';

/// Implementação JSON do repositório de contatos.
/// Lê e grava `contatos.json` no diretório de suporte da aplicação.
final class JsonContactRepository implements ContactRepository {
  JsonContactRepository(this._baseDir);

  final String _baseDir;

  File get _file => File('$_baseDir/contatos.json');

  static Future<JsonContactRepository> create() async {
    final dir = await getApplicationSupportDirectory();
    return JsonContactRepository(dir.path);
  }

  @override
  Future<List<Contact>> getAll() async {
    if (!await _file.exists()) return [];
    try {
      final data = jsonDecode(await _file.readAsString()) as List<dynamic>;
      return data.cast<Map<String, dynamic>>().map(Contact.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveAll(List<Contact> contacts) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      jsonEncode(contacts.map((c) => c.toJson()).toList()),
    );
  }

  @override
  Future<List<Contact>> importFromFile(String path) async {
    final raw = await File(path).readAsString();
    final data = jsonDecode(raw) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(Contact.fromJson).toList();
  }

  @override
  Future<String> exportToFile(List<Contact> contacts, String outputPath) async {
    final file = File(outputPath);
    await file.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(contacts.map((c) => c.toJson()).toList()),
    );
    return file.path;
  }
}
