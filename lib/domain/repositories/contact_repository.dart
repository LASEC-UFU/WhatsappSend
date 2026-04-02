import '../entities/contact.dart';

/// Contrato do repositório de contatos — Dependency Inversion Principle.
abstract interface class ContactRepository {
  Future<List<Contact>> getAll();
  Future<void> saveAll(List<Contact> contacts);
  Future<List<Contact>> importFromFile(String path);
  Future<String> exportToFile(List<Contact> contacts, String outputPath);
}
