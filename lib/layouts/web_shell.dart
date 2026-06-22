import 'package:flutter/material.dart';
import '../data/auth_roles.dart';
import '../utils/responsive.dart';
import '../widgets/web_navigation_rail.dart';
import '../widgets/web_top_bar.dart';

class WebShell extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;
  final UserRole? role;

  const WebShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final extended = Responsive.widthOf(context) >= Responsive.desktopBreakpoint;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Row(
        children: [
          WebNavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: extended,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WebTopBar(
                  title: WebTopBar.titleForIndex(selectedIndex),
                  role: role,
                ),
                Expanded(
                  child: ResponsiveContent(child: child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
