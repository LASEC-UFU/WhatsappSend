import '../entities/app_config.dart';

/// Contrato do repositório de configurações — Dependency Inversion Principle.
abstract interface class ConfigRepository {
  Future<AppConfig> get();
  Future<void> save(AppConfig config);
}
