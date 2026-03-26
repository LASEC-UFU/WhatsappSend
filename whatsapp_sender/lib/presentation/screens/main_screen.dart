import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../providers/contacts_provider.dart';
import '../providers/send_provider.dart';
import 'config_screen.dart';
import 'contacts_screen.dart';
import 'message_screen.dart';
import 'send_screen.dart';

/// Tela principal com abas — espelho da janela Tkinter do app Python.
/// Responsiva: NavigationRail no desktop, BottomNavigationBar no mobile.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    _TabItem(icon: Icons.people_outline, label: 'Contatos'),
    _TabItem(icon: Icons.message_outlined, label: 'Mensagem & Arquivos'),
    _TabItem(icon: Icons.settings_outlined, label: 'Configurações'),
    _TabItem(icon: Icons.send, label: 'Enviar'),
  ];

  static const double _wideBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;

          if (isWide) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _tabIndex,
                  onDestinationSelected: (i) => setState(() => _tabIndex = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: AppColors.waDarkGreen,
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.waGreen,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: Color(0xFF80CBC4),
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.waGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Color(0xFF80CBC4),
                    fontSize: 11,
                  ),
                  indicatorColor: AppColors.waGreen.withValues(alpha: 0.15),
                  destinations: _tabs
                      .map(
                        (t) => NavigationRailDestination(
                          icon: Icon(t.icon),
                          label: Text(t.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: IndexedStack(
                    index: _tabIndex,
                    children: const [
                      ContactsScreen(),
                      MessageScreen(),
                      ConfigScreen(),
                      SendScreen(),
                    ],
                  ),
                ),
              ],
            );
          }

          return IndexedStack(
            index: _tabIndex,
            children: const [
              ContactsScreen(),
              MessageScreen(),
              ConfigScreen(),
              SendScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar:
          MediaQuery.of(context).size.width >= _wideBreakpoint
              ? null
              : _buildNavBar(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final contacts = context.watch<ContactsProvider>();
    final sending = context.select<SendProvider, bool>((s) => s.isSending);
    final sent = contacts.sentCount;
    final errors = contacts.errorCount;

    String subtitle = '${contacts.total} contato(s)';
    if (sent > 0 || errors > 0) {
      subtitle =
          '✓ $sent enviados   '
          '${errors > 0 ? "✗ $errors erros   " : ""}'
          'de ${contacts.total}';
    }

    return AppBar(
      title: Row(
        children: [
          const Text('💬', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          const Text(
            'WhatsApp Sender',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (sending) ...[
            const SizedBox(width: 16),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.waGreen),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'enviando…',
              style: TextStyle(fontSize: 12, color: AppColors.waBubble),
            ),
          ],
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFFA8E6CF)),
          ),
        ),
      ],
    );
  }

  BottomNavigationBar _buildNavBar() {
    return BottomNavigationBar(
      currentIndex: _tabIndex,
      onTap: (i) => setState(() => _tabIndex = i),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.waDarkGreen,
      selectedItemColor: AppColors.waGreen,
      unselectedItemColor: const Color(0xFF80CBC4),
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: _tabs
          .map(
            (t) => BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
          )
          .toList(),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
