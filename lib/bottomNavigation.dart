import 'package:day_condition/pages/statistics.dart';
import 'package:flutter/material.dart';

import 'pages/canlendar.dart';
import 'pages/settings.dart';

class BottomNavigationExample extends StatefulWidget {
  const BottomNavigationExample({
    super.key,
    required this.useLightMode,
    required this.handleBrightnessChange,
  });

  final bool useLightMode;
  final Function(bool useLightMode) handleBrightnessChange;

  @override
  State<BottomNavigationExample> createState() => _BottomNavigationExampleState();
}

class _BottomNavigationExampleState extends State<BottomNavigationExample> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget navigationBar = Focus(
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: exampleBarDestinations,
      ),
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Canlendar(
            useLightMode: widget.useLightMode,
            isReTap: true,
          ),
          Statistics(
            isReTap: true,
          ),
          Settings(useLightMode: widget.useLightMode, handleBrightnessChange: widget.handleBrightnessChange),
        ],
      ),
      bottomNavigationBar: navigationBar,
    );
  }
}

const List<Widget> exampleBarDestinations = [
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.calendar_month),
    label: '캘린더',
    selectedIcon: Icon(Icons.calendar_month),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.bar_chart),
    label: '차트',
    selectedIcon: Icon(Icons.bar_chart),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.settings),
    label: '설정',
    selectedIcon: Icon(Icons.settings),
  )
];
