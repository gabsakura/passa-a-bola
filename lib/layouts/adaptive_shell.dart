import 'package:flutter/material.dart';
import '../data/auth_roles.dart';
import '../layouts/web_shell.dart';
import '../utils/responsive.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../pages/admin_page.dart';

class MobileShell extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final Widget child;
  final UserRole? role;

  const MobileShell({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.child,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'PASSA A BOLA'),
      body: child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
      ),
      floatingActionButton: selectedIndex == 0 && role == UserRole.admin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminPage()),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Painel Admin'),
            )
          : null,
    );
  }
}

/// Escolhe automaticamente entre layout web (sidebar) e mobile (bottom nav).
class AdaptiveShell extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;
  final UserRole? role;

  const AdaptiveShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.useWebShell(context)) {
      return WebShell(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        role: role,
        child: child,
      );
    }

    return MobileShell(
      selectedIndex: selectedIndex,
      onItemTapped: onDestinationSelected,
      role: role,
      child: child,
    );
  }
}
