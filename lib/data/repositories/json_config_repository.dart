import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/app_config.dart';
import '../../domain/repositories/config_repository.dart';

/// Implementação JSON do repositório de configurações.
final class JsonConfigRepository implements ConfigRepository {
  JsonConfigRepository(this._baseDir);

  final String _baseDir;

  File get _file => File('$_baseDir/config.json');

  static Future<JsonConfigRepository> create() async {
    final dir = await getApplicationSupportDirectory();
    return JsonConfigRepository(dir.path);
  }

  @override
  Future<AppConfig> get() async {
    if (!await _file.exists()) return const AppConfig();
    try {
      final data =
          jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
      return AppConfig.fromJson(data);
    } catch (_) {
      return const AppConfig();
    }
  }

  @override
  Future<void> save(AppConfig config) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      const JsonEncoder.withIndent('    ').convert(config.toJson()),
    );
  }
}
