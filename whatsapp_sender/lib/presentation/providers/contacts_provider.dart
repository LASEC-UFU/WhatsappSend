import 'package:flutter/foundation.dart';

import '../../domain/entities/contact.dart';
import '../../domain/repositories/contact_repository.dart';

/// Gerencia a lista de contatos e seus status de envio.
final class ContactsProvider extends ChangeNotifier {
  ContactsProvider(this._repo, List<Contact> initial)
    : _contacts = List.from(initial);

  final ContactRepository _repo;
  final List<Contact> _contacts;

  /// Contatos selecionados na tabela (por id).
  final Set<String> _selectedIds = {};

  List<Contact> get contacts => List.unmodifiable(_contacts);

  List<Contact> get selectedContacts =>
      _contacts.where((c) => _selectedIds.contains(c.id)).toList();

  List<Contact> get errorContacts =>
      _contacts.where((c) => c.status == SendStatus.error).toList();

  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  int get total => _contacts.length;
  int get selectedCount => _selectedIds.length;
  int get errorCount => errorContacts.length;

  int get sentCount =>
      _contacts.where((c) => c.status == SendStatus.sent).length;

  // ── Seleção ──────────────────────────────────────────────────────

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(_contacts.map((c) => c.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  // ── CRUD ─────────────────────────────────────────────────────────

  Future<void> add(Contact contact) async {
    _contacts.add(contact);
    await _save();
  }

  Future<void> update(Contact contact) async {
    final i = _contacts.indexWhere((c) => c.id == contact.id);
    if (i < 0) return;
    _contacts[i] = contact;
    await _save();
  }

  Future<void> removeById(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    _selectedIds.remove(id);
    await _save();
  }

  Future<void> removeSelected() async {
    _contacts.removeWhere((c) => _selectedIds.contains(c.id));
    _selectedIds.clear();
    await _save();
  }

  Future<void> clearAll() async {
    _contacts.clear();
    _selectedIds.clear();
    await _repo.saveAll([]);
    notifyListeners();
  }

  // ── Import / Export ───────────────────────────────────────────────

  Future<int> importFromFile(String path, {bool replace = true}) async {
    final imported = await _repo.importFromFile(path);
    if (replace) {
      _contacts.clear();
      _selectedIds.clear();
    }
    _contacts.addAll(imported);
    await _save();
    return imported.length;
  }

  Future<String> exportToFile(String outputPath) =>
      _repo.exportToFile(_contacts, outputPath);

  // ── Status de envio ───────────────────────────────────────────────

  void updateStatus(
    String contactId,
    String phone,
    String statusStr,
    String detail,
  ) {
    final status = _parseStatus(statusStr);
    final i = _contacts.indexWhere((c) => c.id == contactId);
    if (i >= 0) {
      _contacts[i] = _contacts[i].copyWith(
        status: status,
        statusDetail: detail,
      );
      notifyListeners();
    }
  }

  void resetStatuses() {
    for (int i = 0; i < _contacts.length; i++) {
      _contacts[i] = _contacts[i].copyWith(
        status: SendStatus.pending,
        statusDetail: '',
      );
    }
    notifyListeners();
  }

  // ── Privado ───────────────────────────────────────────────────────

  Future<void> _save() async {
    await _repo.saveAll(_contacts);
    notifyListeners();
  }

  static SendStatus _parseStatus(String s) => switch (s) {
    'enviado' => SendStatus.sent,
    'erro' => SendStatus.error,
    'ignorado' => SendStatus.ignored,
    _ => SendStatus.pending,
  };
}
