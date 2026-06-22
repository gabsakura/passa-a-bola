import 'package:flutter/material.dart';
import 'package:passaabola/pages/jogos_page.dart';
import 'perfil_page.dart';
import '../widgets/article_list_widget.dart';
import 'home_page.dart';
import 'nearby_championships_page.dart';
import '../data/auth_roles.dart';
import '../layouts/adaptive_shell.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  UserRole? _role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRole();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRole();
    }
  }

  Future<void> _loadRole() async {
    RoleService.clearAllCaches();
    final role = await RoleService().getCurrentUserRole();
    if (!mounted) return;
    setState(() {
      _role = role;
    });
  }

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    NearbyChampionshipsPage(),
    JogosPage(),
    ArticleListWidget(showAllArticles: false),
    PerfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      role: _role,
      child: _pages[_selectedIndex],
    );
  }
}
