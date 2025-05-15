import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'auth_screen.dart';
import 'config_screen.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    MapScreen(),
    AuthScreen(),
    ConfigScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.map),
      label: 'Mapa',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Conta',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Config',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: _navItems,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.deepBlue,
        unselectedItemColor: AppColors.subtitle,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
