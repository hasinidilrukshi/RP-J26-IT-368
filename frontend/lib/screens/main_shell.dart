import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'food/food_home_screen.dart';
import 'food/food_preferences_screen.dart';
import 'home/home_screen.dart';

/// Bottom navigation: Home · Explore · Safety · Food · Profile.
///
/// Every tab has its own Navigator, so food screens keep the bottom bar visible
/// (as in the design). Replace the placeholder tabs with your existing screens.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const foodTab = 3;

  /// Lets any screen switch tabs, e.g. `MainShell.of(context)?.selectTab(MainShell.foodTab)`.
  static MainShellState? of(BuildContext context) => context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _index = 0;
  final _navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  void selectTab(int i) {
    if (i == _index) {
      // tapping the active tab returns to its first screen
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  Widget _tabRoot(int i) {
    switch (i) {
      case 0:
        return HomeScreen(onOpenFood: () => selectTab(MainShell.foodTab));
      case 1:
        return const _PlaceholderTab(title: 'Explore', icon: Icons.map_outlined);
      case 2:
        return const _PlaceholderTab(title: 'Safety', icon: Icons.shield_outlined);
      case 3:
        return const FoodHomeScreen();
      default:
        return const _ProfileTab();
    }
  }

  Widget _buildNavigator(int i) => Navigator(
        key: _navKeys[i],
        onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => _tabRoot(i), settings: settings),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: List.generate(5, _buildNavigator)),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: selectTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textGrey,
            selectedFontSize: 11.5,
            unselectedFontSize: 11.5,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Explore'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield), label: 'Safety'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_outlined), activeIcon: Icon(Icons.restaurant), label: 'Food'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('$title screen goes here', style: const TextStyle(color: AppColors.textGrey)),
          ]),
        ),
      );
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.health_and_safety_outlined, color: AppColors.primary),
              title: const Text('Health & dietary profile'),
              subtitle: const Text('Allergies, medical conditions, diet'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const FoodPreferencesScreen())),
            ),
          ),
        ]),
      );
}
