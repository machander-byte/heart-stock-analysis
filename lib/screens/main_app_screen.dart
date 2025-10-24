import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'tips_screen.dart';
import 'assistant_screen.dart';
import 'settings/settings_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  // Lazily create pages to avoid building all tabs on startup.
  final List<Widget?> _pages = List<Widget?>.filled(4, null, growable: false);

  @override
  void initState() {
    super.initState();
    _ensurePage(0); // Create the initial tab only
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        return RecommendedTipsScreen();
      case 2:
        return HealthAssistantScreen();
      case 3:
      default:
        return SettingsScreen();
    }
  }

  void _ensurePage(int index) {
    if (_pages[index] == null) {
      _pages[index] = _buildPage(index);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _ensurePage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List<Widget>.generate(
          _pages.length,
          (i) => _pages[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF00ACC1),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Tips'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Assistant'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
