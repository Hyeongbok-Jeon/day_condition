import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_database/firebase_database.dart';

import '../utils.dart';
import 'globalVariables.dart';

class Canlendar extends StatefulWidget {
  const Canlendar({super.key});

  @override
  _CanlendarState createState() => _CanlendarState();
}

class _CanlendarState extends State<Canlendar> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
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
      appBar: AppBar(
        title: Text("현재시간: ${DateFormat('yyyy-MM-dd hh:mm').format(DateTime.now())}"),
        actions: [
          if (_selectedDay!.compareTo(DateTime.now()) == -1)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                // int dateCompareResult = _selectedDay!.compareTo(DateTime.now());
                // if (dateCompareResult == 1) {
                //   showDialog(
                //     context: context,
                //     builder: (BuildContext context) {
                //       return AlertDialog(
                //         // title: Text('Confirmation'),
                //         content: Text('오늘 이전 날짜만 선택 가능합니다.\n현재시간: ${DateTime.now()}'),
                //         actions: [
                //           TextButton(
                //             onPressed: () {
                //               Navigator.of(context).pop(); // 다이얼로그 닫기
                //             },
                //             child: const Text('확인'),
                //           ),
                //         ],
                //       );
                //     },
                //   );
                //   return;
                // }

                int wakeupTimeHH = 6;
                int bedTimeHH = 22;
                int wakeupTimeMM = 0;
                int bedTimeMM = 0;
                dynamic ratingValue = 2.5;
                String? memo;

                /**
                 * DB에 데이터가 존재 시 가져옴
                 */
                final key = DateFormat('yyyyMMdd').format(_selectedDay!);
                DataSnapshot snapshot = await ref.child(key).get();
                if (snapshot.exists) {
                  Map<dynamic, dynamic> snapshotValue = snapshot.value as Map<dynamic, dynamic>;
                  wakeupTimeHH = int.parse(snapshotValue['wakeupTime'].split(':')[0]);
                  wakeupTimeMM = int.parse(snapshotValue['wakeupTime'].split(':')[1]);
                  bedTimeHH = int.parse(snapshotValue['bedTime'].split(':')[0]);
                  bedTimeMM = int.parse(snapshotValue['bedTime'].split(':')[1]);
                  ratingValue = snapshotValue['energy'];
                  // db의 값이 flutter 변수로 할당되면서 정수는 int로 소수점은 float으로 됨
                  // 때문에 int는 double로 변환
                  ratingValue = ratingValue is int ? snapshotValue['energy'].toDouble() : ratingValue;
                  memo = snapshotValue['memo'];
                }

                DateTime wakeupTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, wakeupTimeHH, wakeupTimeMM);
                DateTime bedTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, bedTimeHH, bedTimeMM);

                // Don't use 'BuildContext's across async gaps. (Documentation)  Try rewriting the code to not reference the 'BuildContext'.
                // 위 에러 해결 코드
                if(!mounted) return;

                showModalBottomSheet<void>(
                  // modal 높이 조절을 위해서는 true로 설정
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0)),
                  ),
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 500 + (MediaQuery.of(context).viewInsets.bottom / 2),
                      child: StatefulBuilder(builder: (BuildContext context, StateSetter modalSetState) {
                        int dateCompareResult = wakeupTime.compareTo(bedTime);
                        return Container(
                          padding: EdgeInsets.fromLTRB(30, 0, 30, MediaQuery.of(context).viewInsets.bottom),
                          child: Container(
                            decoration: borderForDebug,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  decoration: borderForDebug,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('yyyy.MM.dd').format(_selectedDay!),
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                      TextButton(
                                        onPressed: () async => {
                                          await ref.update({
                                            key: {
                                              "wakeupTime": DateFormat('HH:mm').format(wakeupTime),
                                              "bedTime": DateFormat('HH:mm').format(bedTime),
                                              "energy": ratingValue,
                                              "timeDiff": dateCompareResult == -1
                                                  ? (24 * 60) - bedTime.difference(wakeupTime).inMinutes
                                                  : wakeupTime.difference(bedTime).inMinutes,
                                              'memo': memo
                                            }
                                          })
                                              .then((value) {
                                            setState(() {
                                              Navigator.pop(context);
                                            });
                                          })
                                        },
                                        child: const Icon(Icons.check, size: 30,),
                                        // child: const Text('완료', style: TextStyle(fontSize: 30),),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: borderForDebug,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        decoration: borderForDebug,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              decoration: borderForDebug,
                                              child: const Icon(
                                                Icons.nightlight_round_rounded,
                                                color: Colors.indigo,
                                                size: 40,
                                              ),
                                            ),
                                            // Container(
                                            //   decoration: borderForDebug,
                                            //   child: CupertinoButton(
                                            //     // Display a CupertinoDatePicker in dateTime picker mode.
                                            //     onPressed: () => _showDialog(
                                            //       CupertinoDatePicker(
                                            //         initialDateTime: bedTime,
                                            //         mode: CupertinoDatePickerMode.time,
                                            //         use24hFormat: false,
                                            //         // This is called when the user changes the dateTime.
                                            //         onDateTimeChanged: (DateTime newDateTime) {
                                            //           modalSetState(() => bedTime = newDateTime);
                                            //         },
                                            //       ),
                                            //     ),
                                            //     // In this example, the time value is formatted manually. You
                                            //     // can use the intl package to format the value based on the
                                            //     // user's locale settings.
                                            //     child: Text(
                                            //       DateFormat('HH:mm').format(bedTime),
                                            //       // '${bedTime.hour}:${bedTime.minute}',
                                            //       style: const TextStyle(
                                            //         fontSize: 20,
                                            //       ),
                                            //     ),
                                            //   ),
                                            // ),
                                            Container(
                                              decoration: borderForDebug,
                                              child: TextButton(
                                                onPressed: () => _showDialog(
                                                  CupertinoDatePicker(
                                                    initialDateTime: bedTime,
                                                    mode: CupertinoDatePickerMode.time,
                                                    use24hFormat: true,
                                                    // This is called when the user changes the dateTime.
                                                    onDateTimeChanged: (DateTime newDateTime) {
                                                      modalSetState(() => bedTime = newDateTime);
                                                    },
                                                  ),
                                                ),
                                                child: Text(
                                                    DateFormat('HH:mm').format(bedTime),
                                                    style: const TextStyle(fontSize: 30),
                                                ),
                                              )
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: borderForDebug,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              decoration: borderForDebug,
                                              child: const Icon(
                                                Icons.sunny,
                                                color: Colors.yellow,
                                                size: 40,
                                              ),
                                            ),
                                            // CupertinoButton(
                                            //   padding: const EdgeInsets.only(top: 0, bottom: 0),
                                            //   // Display a CupertinoDatePicker in dateTime picker mode.
                                            //   onPressed: () => _showDialog(
                                            //     CupertinoDatePicker(
                                            //       initialDateTime: wakeupTime,
                                            //       mode: CupertinoDatePickerMode.time,
                                            //       use24hFormat: false,
                                            //       // This is called when the user changes the dateTime.
                                            //       onDateTimeChanged: (DateTime newDateTime) {
                                            //         modalSetState(() => wakeupTime = newDateTime);
                                            //       },
                                            //     ),
                                            //   ),
                                            //   // In this example, the time value is formatted manually. You
                                            //   // can use the intl package to format the value based on the
                                            //   // user's locale settings.
                                            //   child: Text(
                                            //     DateFormat('HH:mm').format(wakeupTime),
                                            //     style: const TextStyle(
                                            //       fontSize: 40,
                                            //     ),
                                            //   ),
                                            // ),
                                            Container(
                                                decoration: borderForDebug,
                                                child: TextButton(
                                                  onPressed: () => _showDialog(
                                                    CupertinoDatePicker(
                                                      initialDateTime: wakeupTime,
                                                      mode: CupertinoDatePickerMode.time,
                                                      use24hFormat: true,
                                                      // This is called when the user changes the dateTime.
                                                      onDateTimeChanged: (DateTime newDateTime) {
                                                        modalSetState(() => wakeupTime = newDateTime);
                                                      },
                                                    ),
                                                  ),
                                                  child: Text(
                                                    DateFormat('HH:mm').format(wakeupTime),
                                                    style: const TextStyle(fontSize: 30),
                                                  ),
                                                )
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: borderForDebug,
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
                                        itemBuilder: (context, _) => const Icon(
                                          // Image.asset(name),
                                          Icons.rectangle_rounded,
                                          color: Colors.green,
                                        ),
                                        onRatingUpdate: (rating) {
                                          ratingValue = rating;
                                        },
                                        itemSize: 50,
                                      )
                                    ],
                                  ),
                                ),
                                TextField(
                                  maxLines: 5,
                                  controller: TextEditingController(text: memo),
                                  decoration: const InputDecoration(
                                    labelText: 'memo',
                                    border: OutlineInputBorder(),
                                    // contentPadding: EdgeInsets.symmetric(vertical: 50),
                                  ),
                                  onChanged: (value) {
                                    memo = value;
                                  },
                                  keyboardType: TextInputType.multiline,
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                    );
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
            )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: borderForDebug,
              child: TableCalendar<Event>(
                availableCalendarFormats: const {
                  CalendarFormat.month: '월',
                },
                locale: 'ko_KR',
                rowHeight: 80,
                daysOfWeekHeight: 30,
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
                calendarStyle: CalendarStyle(
                  // Use `CalendarStyle` to customize the UI
                  // outsideDaysVisible: true,
                  cellAlignment: Alignment.topLeft,
                  selectedTextStyle: const TextStyle(
                    color: Colors.black,
                    // backgroundColor: Colors.redAccent,
                  ),
                  selectedDecoration: BoxDecoration(
                    border: Border.all(width: 2, color: Colors.blueAccent),
                    color: Colors.transparent,
                    shape: BoxShape.rectangle,
                  ),
                  // markerDecoration: BoxDecoration(
                  //   color: Colors.green,
                  //   // shape: BoxShape.rectangle,
                  // ),
                  todayTextStyle: const TextStyle(
                    color: Colors.blueAccent,
                    // backgroundColor: Colors.redAccent,
                  ),
                  todayDecoration: const BoxDecoration(
                    color: Colors.transparent,
                    // shape: BoxShape.rectangle,
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
                    headerTitleBuilder: (BuildContext context, DateTime day) {
                      return Container(
                        decoration: borderForDebug,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                decoration: borderForDebug,
                                child: Text(
                                  '${day.year}년 ${day.month}월',
                                  style: const TextStyle(fontSize: 18),
                                )
                            ),
                            Container(
                              decoration: borderForDebug,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedDay = DateTime.now();
                                    _focusedDay = DateTime.now();
                                  });
                                },
                                child: const Text(
                                  '오늘',
                                  style: TextStyle(fontSize: 18),
                                )
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    markerBuilder: (context, day, events) {
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
                            return Column(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.035,),
                                Container(
                                  // width: MediaQuery.of(context).size.width * 0.2,
                                  // padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.035),
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
                                              color: G_sleepColor,
                                              borderRadius: BorderRadius.circular(500),
                                            ),
                                            child: Text(
                                              bedTime,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: MediaQuery.of(context).size.height * 0.01
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
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
                                              child: Text(
                                                wakeupTime,
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: MediaQuery.of(context).size.height * 0.01
                                                ),
                                              ),
                                            )
                                          ]
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
                                            itemSize: MediaQuery.of(context).size.height * 0.01
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                onDayLongPressed: (DateTime selectedDay, DateTime focusedDay) async {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}