import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/json_config_repository.dart';
import 'data/repositories/json_contact_repository.dart';
import 'presentation/providers/config_provider.dart';
import 'presentation/providers/contacts_provider.dart';
import 'presentation/providers/send_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final contactRepo = await JsonContactRepository.create();
  final configRepo = await JsonConfigRepository.create();

  final contacts = await contactRepo.getAll();
  final config = await configRepo.get();

  final contactsProvider = ContactsProvider(contactRepo, contacts);
  final configProvider = ConfigProvider(configRepo, config);
  final sendProvider = await SendProvider.build();

  runApp(
    WhatsAppSenderApp(
      contactsProvider: contactsProvider,
      configProvider: configProvider,
      sendProvider: sendProvider,
    ),
  );
}