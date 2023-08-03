import 'package:day_condition/userData.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';

import '../utils.dart';
import 'globalVariables.dart';

class TableEventsExample extends StatefulWidget {
  const TableEventsExample({super.key});

  @override
  _TableEventsExampleState createState() => _TableEventsExampleState();
}

class _TableEventsExampleState extends State<TableEventsExample> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference ref = FirebaseDatabase.instance.ref("$G_uid");

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    initializeDateFormatting('ko_KR', null);
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Implementation example
    return kEvents[day] ?? [];
  }

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    // Implementation example
    final days = daysInRange(start, end);

    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // `start` or `end` could be null
    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => Container(
          height: 216,
          padding: const EdgeInsets.only(top: 6.0),
          // The Bottom margin is provided to align the popup above the system
          // navigation bar.
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          // Provide a background color for the popup.
          color: CupertinoColors.systemBackground.resolveFrom(context),
          // Use a SafeArea widget to avoid system overlaps.
          child: SafeArea(
            top: false,
            child: child,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 55, 0, 20),
                width: 200,
                height: 50,
                // color: Colors.blue,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  // shape: BoxShape.circle, // 타원형 모양으로 설정
                ),// 네모난 박스의 색상
                child: const Center(
                  child: Text(
                    'Day Condition',
                    style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            TableCalendar<Event>(
              availableCalendarFormats: const {
                CalendarFormat.month: '월',
              },
              locale: 'ko_KR',
              rowHeight: MediaQuery.of(context).size.height * 0.13,
              firstDay: kFirstDay,
              lastDay: kLastDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              calendarFormat: _calendarFormat,
              rangeSelectionMode: _rangeSelectionMode,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: const CalendarStyle(
                // Use `CalendarStyle` to customize the UI
                outsideDaysVisible: false,
                cellAlignment: Alignment.topCenter,
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF5C6BC0),
                  shape: BoxShape.rectangle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFF9FA8DA),
                  shape: BoxShape.rectangle,
                ),
              ),
              onDaySelected: _onDaySelected,
              onRangeSelected: _onRangeSelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events){
                    final key = DateFormat('yyyyMMdd').format(day);

                    Future<Map<dynamic, dynamic>> getMarkersAsync() async {
                      DataSnapshot snapshot = await ref.child(key).get();
                      return snapshot.value as Map<dynamic, dynamic>;
                    }

                    return FutureBuilder(
                      future: getMarkersAsync(),
                      builder: (context, snapShot) {
                        if (snapShot.hasData) {
                          String wakeupTime = snapShot.data?["wakeupTime"];
                          String bedTime = snapShot.data?["bedTime"];
                          dynamic energy = snapShot.data?["energy"];
                          if (energy is int) {
                            energy = energy.toDouble();
                          }
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.11,
                            padding: const EdgeInsets.only(top: 30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        margin: const EdgeInsets.only(bottom: 4),
                                        decoration: BoxDecoration(
                                          color: G_wakeUpColor,
                                          borderRadius: BorderRadius.circular(500),
                                        ),
                                        // child: Text(storage.getItem(day.toString()), style: TextStyle(color: Colors.black),),
                                        child: Text(wakeupTime, style: const TextStyle(color: Colors.black),),
                                      )
                                    ]
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: G_sleepColor,
                                        borderRadius: BorderRadius.circular(500),
                                      ),
                                      child: Text(bedTime, style: const TextStyle(color: Colors.white),),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    RatingBar.builder(
                                      ignoreGestures: true,
                                      initialRating: energy,
                                      minRating: 1,
                                      direction: Axis.horizontal,
                                      allowHalfRating: true,
                                      itemCount: 5,
                                      itemPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                      itemBuilder: (context, _) => Icon(
                                        // Image.asset(name),
                                        Icons.rectangle_rounded,
                                        color: G_energyColor,
                                      ),
                                      onRatingUpdate: (rating) {
                                      },
                                      itemSize: 8,
                                    )
                                  ],
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      }
                    );
                  },
                  dowBuilder: (context, day) {
                    return null;
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    return null;
                  },
              ),
              onDayLongPressed: (DateTime selectedDay, DateTime focusedDay) async {
                int wakeupTimeHH = 6;
                int bedTimeHH = 22;
                int wakeupTimeMM = 0;
                int bedTimeMM = 0;
                dynamic ratingValue = 2.5;
                final key = DateFormat('yyyyMMdd').format(selectedDay);
                DataSnapshot snapshot = await ref.child(key).get();
                if (snapshot.exists) {
                  Map<dynamic, dynamic> value = snapshot.value as Map<dynamic, dynamic>;
                  wakeupTimeHH = int.parse(value['wakeupTime'].split(':')[0]);
                  wakeupTimeMM = int.parse(value['wakeupTime'].split(':')[1]);
                  bedTimeHH = int.parse(value['bedTime'].split(':')[0]);
                  bedTimeMM = int.parse(value['bedTime'].split(':')[1]);
                  ratingValue = value['energy'];
                  if (ratingValue is int) {
                    ratingValue = value['energy'].toDouble();
                  }
                }
                DateTime wakeupTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, wakeupTimeHH, wakeupTimeMM);
                DateTime bedTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, bedTimeHH, bedTimeMM);
                if(!mounted) return;
                showModalBottomSheet<void>(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0)),
                  ),
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(builder: (BuildContext context, StateSetter modalSetState) {
                      return SizedBox(
                          height: 400,
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    // crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('yyyy.MM.dd').format(selectedDay),
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                      TextButton(
                                        onPressed: () async => {
                                          await ref.update({
                                            key: {
                                              "wakeupTime": DateFormat('HH:mm').format(wakeupTime),
                                              "bedTime": DateFormat('HH:mm').format(bedTime),
                                              "energy": ratingValue
                                            }
                                          }),
                                          setState(() {
                                            Navigator.pop(context);
                                          })
                                        },
                                        child: const Icon(Icons.check, size: 30,),
                                        // child: const Text('완료', style: TextStyle(fontSize: 30),),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.sunny,
                                      color: Colors.yellow,
                                      size: 50,
                                    ),
                                    CupertinoButton(
                                      // Display a CupertinoDatePicker in dateTime picker mode.
                                      onPressed: () => _showDialog(
                                        CupertinoDatePicker(
                                          initialDateTime: wakeupTime,
                                          mode: CupertinoDatePickerMode.time,
                                          use24hFormat: false,
                                          // This is called when the user changes the dateTime.
                                          onDateTimeChanged: (DateTime newDateTime) {
                                            modalSetState(() => wakeupTime = newDateTime);
                                          },
                                        ),
                                      ),
                                      // In this example, the time value is formatted manually. You
                                      // can use the intl package to format the value based on the
                                      // user's locale settings.
                                      child: Text(
                                        DateFormat('HH:mm').format(wakeupTime),
                                        style: const TextStyle(
                                          fontSize: 50,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.nightlight_round_rounded,
                                      color: Colors.indigo,
                                      size: 50,
                                    ),
                                    CupertinoButton(
                                      // Display a CupertinoDatePicker in dateTime picker mode.
                                      onPressed: () => _showDialog(
                                        CupertinoDatePicker(
                                          initialDateTime: bedTime,
                                          mode: CupertinoDatePickerMode.time,
                                          use24hFormat: false,
                                          // This is called when the user changes the dateTime.
                                          onDateTimeChanged: (DateTime newDateTime) {
                                            modalSetState(() => bedTime = newDateTime);
                                          },
                                        ),
                                      ),
                                      // In this example, the time value is formatted manually. You
                                      // can use the intl package to format the value based on the
                                      // user's locale settings.
                                      child: Text(
                                        DateFormat('HH:mm').format(bedTime),
                                        // '${bedTime.hour}:${bedTime.minute}',
                                        style: const TextStyle(
                                          fontSize: 50,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      RatingBar.builder(
                                        initialRating: ratingValue,
                                        minRating: 1,
                                        direction: Axis.horizontal,
                                        allowHalfRating: true,
                                        itemCount: 5,
                                        itemPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                        itemBuilder: (context, _) => const Icon(
                                          // Image.asset(name),
                                          Icons.rectangle_rounded,
                                          color: Colors.green,
                                        ),
                                        onRatingUpdate: (rating) {
                                          ratingValue = rating;
                                        },
                                        itemSize: 64,
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                      );
                    });
                    // return Container(
                    //   height: 500,
                    //   color: Colors.amber,
                    //   child: Center(
                    //     child: Column(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: <Widget>[
                    //         const Text('Modal BottomSheet'),
                    //         ElevatedButton(
                    //           child: const Text('Done!'),
                    //           onPressed: () => Navigator.pop(context),
                    //         )
                    //       ],
                    //     ),
                    //   ),
                    // );
                  },
                );
              },
            ),
            // const SizedBox(height: 8.0),
            // Expanded(
            //   child: ValueListenableBuilder<List<Event>>(
            //     valueListenable: _selectedEvents,
            //     builder: (context, value, _) {
            //       return ListView.builder(
            //         itemCount: value.length,
            //         itemBuilder: (context, index) {
            //           return Container(
            //             margin: const EdgeInsets.symmetric(
            //               horizontal: 12.0,
            //               vertical: 4.0,
            //             ),
            //             decoration: BoxDecoration(
            //               border: Border.all(),
            //               borderRadius: BorderRadius.circular(12.0),
            //             ),
            //             child: ListTile(
            //               onTap: () => print('${value[index]}'),
            //               title: Text('${value[index]}'),
            //             ),
            //           );
            //         },
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}