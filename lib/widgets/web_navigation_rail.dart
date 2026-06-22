import 'package:flutter/material.dart';
import '../data/constants.dart';

class WebNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;

  const WebNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.extended,
  });

  static const _destinations = [
    (icon: Icons.home_outlined, selected: Icons.home, label: 'Início'),
    (icon: Icons.map_outlined, selected: Icons.map, label: 'Próximos'),
    (icon: Icons.sports_soccer_outlined, selected: Icons.sports_soccer, label: 'Jogos'),
    (icon: Icons.article_outlined, selected: Icons.article, label: 'Notícias'),
    (icon: Icons.person_outline, selected: Icons.person, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: extended,
      minExtendedWidth: 180,
      backgroundColor: KConstants.primaryColor,
      indicatorColor: KConstants.successColor.withValues(alpha: 0.25),
      selectedIconTheme: const IconThemeData(
        color: KConstants.successColor,
        size: 28,
      ),
      unselectedIconTheme: IconThemeData(
        color: KConstants.textLightColor.withValues(alpha: 0.85),
        size: 26,
      ),
      selectedLabelTextStyle: KTextStyle.bodyText.copyWith(
        color: KConstants.successColor,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: KTextStyle.bodyText.copyWith(
        color: KConstants.textLightColor.withValues(alpha: 0.85),
      ),
      leading: Padding(
        padding: EdgeInsets.symmetric(vertical: extended ? 16 : 12),
        child: Icon(
          Icons.sports_soccer,
          color: KConstants.textLightColor,
          size: extended ? 36 : 30,
        ),
      ),
      destinations: [
        for (final item in _destinations)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selected),
            label: Text(item.label),
          ),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
    );
  }
}
