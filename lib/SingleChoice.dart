import 'package:day_condition/models/userSetting.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'globalVariables.dart';

class SingleChoice extends StatefulWidget {
  const SingleChoice({super.key, required this.snapshot});

  final Map<String, dynamic> snapshot;

  @override
  State<SingleChoice> createState() => _SingleChoiceState();
}

class _SingleChoiceState extends State<SingleChoice> {
  final ref = FirebaseDatabase.instance.ref('$G_uid/settings');

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StartingDayOfWeek>(
      segments: const <ButtonSegment<StartingDayOfWeek>>[
        ButtonSegment<StartingDayOfWeek>(
            value: StartingDayOfWeek.sunday, label: Text('일요일'), icon: Icon(Icons.calendar_month)),
        ButtonSegment<StartingDayOfWeek>(
            value: StartingDayOfWeek.monday, label: Text('월요일'), icon: Icon(Icons.calendar_month)),
      ],
      selected: <StartingDayOfWeek>{
        widget.snapshot['startingDayOfWeek'] == 'sunday' ? StartingDayOfWeek.sunday : StartingDayOfWeek.monday
      },
      onSelectionChanged: (newSelection) {
        ref.update({
          'startingDayOfWeek': newSelection.first == StartingDayOfWeek.sunday ? 'sunday' : 'monday',
        });
      },
    );
  }
}
