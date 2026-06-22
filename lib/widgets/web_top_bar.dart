import 'package:flutter/material.dart';
import '../data/auth_roles.dart';
import '../data/constants.dart';
import '../pages/admin_page.dart';

class WebTopBar extends StatelessWidget {
  final String title;
  final UserRole? role;

  const WebTopBar({
    super.key,
    required this.title,
    this.role,
  });

  static const _titles = [
    'Início',
    'Campeonatos Próximos',
    'Jogos',
    'Notícias',
    'Perfil',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'PASSA A BOLA',
                  style: KTextStyle.titleText.copyWith(
                    color: KConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  title,
                  style: KTextStyle.bodySecondaryText.copyWith(
                    fontSize: KConstants.fontSizeLarge,
                  ),
                ),
                const Spacer(),
                if (role == UserRole.admin)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminPage()),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: KConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.admin_panel_settings, size: 18),
                    label: const Text('Painel Admin'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String titleForIndex(int index) {
    if (index < 0 || index >= _titles.length) return 'Passa a Bola';
    return _titles[index];
  }
}
