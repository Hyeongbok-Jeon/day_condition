import 'package:day_condition/pages/statistics.dart';
import 'package:flutter/material.dart';

import 'pages/canlendar.dart';
import 'pages/settings.dart';

class BottomNavigationExample extends StatefulWidget {
  const BottomNavigationExample({
    super.key,
    required this.useLightMode,
  });

  final bool useLightMode;

  @override
  State<BottomNavigationExample> createState() => _BottomNavigationExampleState();
}

class _BottomNavigationExampleState extends State<BottomNavigationExample> {
  int _currentIndex = 0;
  bool isReTap = false;

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   body: IndexedStack(
    //     index: _currentIndex,
    //     children: [
    //       Canlendar(
    //         isReTap: isReTap,
    //       ),
    //       Statistics(isReTap: true,),
    //       const Settings(),
    //     ],
    //   ),
    //   bottomNavigationBar: BottomNavigationBar(
    //     showSelectedLabels: false,
    //     showUnselectedLabels: false,
    //     currentIndex: _currentIndex,
    //     onTap: (int index) {
    //       if (_currentIndex == index) {
    //         setState(() {
    //           isReTap = true;
    //         });
    //       } else {
    //         setState(() {
    //           _currentIndex = index;
    //           isReTap = false;
    //         });
    //       }
    //     },
    //     items: const [
    //       BottomNavigationBarItem(
    //         icon: Icon(Icons.calendar_month, size: 28),
    //         label: '',
    //       ),
    //       BottomNavigationBarItem(
    //         icon: Icon(Icons.bar_chart, size: 28),
    //         label: '',
    //       ),
    //       BottomNavigationBarItem(
    //         icon: Icon(Icons.settings, size: 28),
    //         label: '',
    //       ),
    //     ],
    //   ),
    // );

    // App NavigationBar should get first focus.
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
            isReTap: isReTap,
          ),
          Statistics(
            isReTap: true,
          ),
          const Settings(),
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
