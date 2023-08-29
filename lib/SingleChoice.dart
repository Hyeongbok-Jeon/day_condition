import 'package:day_condition/models/userSetting.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'globalVariables.dart';

class SingleChoice extends StatefulWidget {
  const SingleChoice({super.key, required this.settingsAsyncSnapshot});

  final AsyncSnapshot<UserSetting> settingsAsyncSnapshot;

  @override
  State<SingleChoice> createState() => _SingleChoiceState();
}

class _SingleChoiceState extends State<SingleChoice> {
  final ref = FirebaseDatabase.instance.ref('$G_uid');
  StartingDayOfWeek startingDayOfWeek = StartingDayOfWeek.sunday;

  @override
  Widget build(BuildContext context) {
    if (widget.settingsAsyncSnapshot.hasData) {
      startingDayOfWeek = widget.settingsAsyncSnapshot.data!.startingDayOfWeek;
    }

    return SegmentedButton<StartingDayOfWeek>(
      segments: const <ButtonSegment<StartingDayOfWeek>>[
        ButtonSegment<StartingDayOfWeek>(
            value: StartingDayOfWeek.sunday, label: Text('일요일'), icon: Icon(Icons.calendar_month)),
        ButtonSegment<StartingDayOfWeek>(
            value: StartingDayOfWeek.monday, label: Text('월요일'), icon: Icon(Icons.calendar_month)),
      ],
      selected: <StartingDayOfWeek>{startingDayOfWeek},
      onSelectionChanged: (newSelection) {
        setState(() {
          // By default there is only a single segment that can be
          // selected at one time, so its value is always the first
          // item in the selected set.
          startingDayOfWeek = newSelection.first;
          ref.child('settings').update({
            'startingDayOfWeek': newSelection.first == StartingDayOfWeek.sunday ? 'sunday' : 'monday',
          });
        });
      },
    );
  }
}
