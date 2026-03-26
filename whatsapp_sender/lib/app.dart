import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/config_provider.dart';
import 'presentation/providers/contacts_provider.dart';
import 'presentation/providers/send_provider.dart';
import 'presentation/screens/main_screen.dart';

/// Raiz do aplicativo — configura o MultiProvider e o tema.
class WhatsAppSenderApp extends StatelessWidget {
  const WhatsAppSenderApp({
    super.key,
    required this.contactsProvider,
    required this.configProvider,
    required this.sendProvider,
  });

  final ContactsProvider contactsProvider;
  final ConfigProvider configProvider;
  final SendProvider sendProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: contactsProvider),
        ChangeNotifierProvider.value(value: configProvider),
        ChangeNotifierProvider.value(value: sendProvider),
      ],
      child: MaterialApp(
        title: 'WhatsApp Sender',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MainScreen(),
      ),
    );
  }
}
