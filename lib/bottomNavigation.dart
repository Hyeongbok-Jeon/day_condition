import 'package:day_condition/statistics.dart';
import 'package:flutter/material.dart';

import 'canlendar.dart';
import 'settings.dart';

class BottomNavigationExample extends StatefulWidget {
  const BottomNavigationExample({super.key});

  @override
  _BottomNavigationExampleState createState() => _BottomNavigationExampleState();
}

class _BottomNavigationExampleState extends State<BottomNavigationExample> {
  int _currentIndex = 0;
  bool isReTap = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: _buildPage(_currentIndex),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Canlendar(isReTap: isReTap,), // 각 탭에 해당하는 페이지 위젯들
          const Statistics(),
          const Settings(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (int index) {
          if (_currentIndex == index) {
            setState(() {
              isReTap = true;
            });
          } else {
            setState(() {
              _currentIndex = index;
              isReTap = false;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 28),
            label: '',
          ),
        ],
      ),
    );
  }
}