import 'package:flutter/material.dart';
import '../core/colors.dart';
import 'screens/smart_input_screen.dart';
import 'screens/equation_screen.dart';
import 'screens/ledger_hub_screen.dart';
import 'screens/reports_hub_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SmartInputScreen(),
    const EquationScreen(),
    const LedgerHubScreen(),
    const ReportsHubScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.cardSurface,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.electricCyan,
        unselectedItemColor: AppColors.secondaryText,
        selectedLabelStyle: const TextStyle(
          overflow: TextOverflow.ellipsis,
        ),
        unselectedLabelStyle: const TextStyle(
          overflow: TextOverflow.ellipsis,
        ),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_button),
            label: 'Smart Input',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Equation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Ledger Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports Hub',
          ),
        ],
      ),
    );
  }
}
