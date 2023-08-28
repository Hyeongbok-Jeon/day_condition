import 'package:day_condition/pages/statistics.dart';
import 'package:flutter/material.dart';

import 'pages/canlendar.dart';
import 'pages/settings.dart';

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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Canlendar(
            isReTap: isReTap,
          ),
          Statistics(isReTap: true,),
          const Settings(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _currentIndex,
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
