import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../utils.dart';
import '../globalVariables.dart';

class Canlendar extends StatefulWidget {
  late bool isReTap;

  Canlendar({Key? key, required this.isReTap}) : super(key: key);

  void setReTapFalse() {
    isReTap = false;
  }

  @override
  _CanlendarState createState() => _CanlendarState();
}

class _CanlendarState extends State<Canlendar> {
  final ref = FirebaseDatabase.instance.ref('$G_uid');
  Map<dynamic, dynamic> snapshotValue = <dynamic, dynamic>{};
  StartingDayOfWeek startingDayOfWeek = StartingDayOfWeek.monday;
  bool isLoading = true;

  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = getKoreanTime();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime? currentTime;

  /// sfDateRangePicker 버튼 Key
  final GlobalKey sfDateRangePickerKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));

    ref.onValue.listen((event) {
      if (mounted) {
        setState(() {
          for (final child in event.snapshot.children) {
            snapshotValue[child.key] = child.value;
          }
          startingDayOfWeek =
              snapshotValue['settings']['startingDayOfWeek'] == 'monday'
                  ? StartingDayOfWeek.monday
                  : StartingDayOfWeek.sunday;
          isLoading = false;
        });
      }
    });
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

    setEvent(selectedDay);
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

  String getDayOfWeekInKorean(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '월요일';
      case DateTime.tuesday:
        return '화요일';
      case DateTime.wednesday:
        return '수요일';
      case DateTime.thursday:
        return '목요일';
      case DateTime.friday:
        return '금요일';
      case DateTime.saturday:
        return '토요일';
      case DateTime.sunday:
        return '일요일';
      default:
        return '';
    }
  }

  /// 이벤트 등록 modal bottom sheet
  Future<void> setEvent(DateTime selectedDay) async {
    int wakeupTimeHH = 6;
    int bedTimeHH = 22;
    int wakeupTimeMM = 0;
    int bedTimeMM = 0;
    dynamic ratingValue = 2.5;
    String memo = '';

    /// DB에 데이터가 존재 시 가져옴
    final key = DateFormat('yyyyMMdd').format(_selectedDay!);
    DataSnapshot snapshot = await ref.child(key).get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> snapshotValue =
          snapshot.value as Map<dynamic, dynamic>;
      wakeupTimeHH = int.parse(snapshotValue['wakeupTime'].split(':')[0]);
      wakeupTimeMM = int.parse(snapshotValue['wakeupTime'].split(':')[1]);
      bedTimeHH = int.parse(snapshotValue['bedTime'].split(':')[0]);
      bedTimeMM = int.parse(snapshotValue['bedTime'].split(':')[1]);
      ratingValue = snapshotValue['energy'];
      // db의 값이 flutter 변수로 할당되면서 정수는 int로 소수점은 float으로 됨
      // 때문에 int는 double로 변환
      ratingValue =
          ratingValue is int ? snapshotValue['energy'].toDouble() : ratingValue;
      memo = snapshotValue['memo'];
    }

    ///

    DateTime wakeupTime = DateTime(selectedDay.year, selectedDay.month,
        selectedDay.day, wakeupTimeHH, wakeupTimeMM);
    DateTime bedTime = DateTime(selectedDay.year, selectedDay.month,
        selectedDay.day, bedTimeHH, bedTimeMM);
    String dayOfWeek = getDayOfWeekInKorean(selectedDay.weekday);

    // Don't use 'BuildContext's across async gaps. (Documentation)  Try rewriting the code to not reference the 'BuildContext'.
    // 위 에러 해결 코드
    if (!mounted) return;

    showModalBottomSheet<void>(
      // modal 높이 조절을 위해서는 true로 설정
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0)),
      ),
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 500 + (MediaQuery.of(context).viewInsets.bottom / 3),
          child: StatefulBuilder(
              builder: (BuildContext context, StateSetter modalSetState) {
            int dateCompareResult = wakeupTime.compareTo(bedTime);
            return Container(
              padding: EdgeInsets.fromLTRB(
                  30, 0, 30, MediaQuery.of(context).viewInsets.bottom),
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
                          Container(
                            decoration: borderForDebug,
                            child: Text(
                              DateFormat('M월 d일 $dayOfWeek')
                                  .format(_selectedDay!),
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          Container(
                            decoration: borderForDebug,
                            child: Row(
                              children: [
                                Container(
                                  decoration: borderForDebug,
                                  child: TextButton(
                                    onPressed: () async => {
                                      await ref
                                          .child(key)
                                          .remove()
                                          .then((value) {
                                        setState(() {
                                          Navigator.pop(context);
                                        });
                                      })
                                    },
                                    child: const Icon(
                                      Icons.delete,
                                      size: 30,
                                    ),
                                    // child: const Text('완료', style: TextStyle(fontSize: 30),),
                                  ),
                                ),
                                Container(
                                  decoration: borderForDebug,
                                  child: TextButton(
                                    onPressed: () async => {
                                      await ref.update({
                                        key: {
                                          "wakeupTime": DateFormat('HH:mm')
                                              .format(wakeupTime),
                                          "bedTime": DateFormat('HH:mm')
                                              .format(bedTime),
                                          "energy": ratingValue,
                                          "timeDiff": dateCompareResult == -1
                                              ? (24 * 60) -
                                                  bedTime
                                                      .difference(wakeupTime)
                                                      .inMinutes
                                              : wakeupTime
                                                  .difference(bedTime)
                                                  .inMinutes,
                                          'memo': memo,
                                        }
                                      }).then((value) {
                                        setState(() {
                                          Navigator.pop(context);
                                        });
                                      })
                                    },
                                    child: const Icon(
                                      Icons.check,
                                      size: 30,
                                    ),
                                    // child: const Text('완료', style: TextStyle(fontSize: 30),),
                                  ),
                                ),
                              ],
                            ),
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
                                          onDateTimeChanged:
                                              (DateTime newDateTime) {
                                            modalSetState(
                                                () => bedTime = newDateTime);
                                          },
                                        ),
                                      ),
                                      child: Text(
                                        DateFormat('HH:mm').format(bedTime),
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                    )),
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
                                          onDateTimeChanged:
                                              (DateTime newDateTime) {
                                            modalSetState(
                                                () => wakeupTime = newDateTime);
                                          },
                                        ),
                                      ),
                                      child: Text(
                                        DateFormat('HH:mm').format(wakeupTime),
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: borderForDebug,
                      // padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RatingBar.builder(
                            initialRating: ratingValue,
                            minRating: 1,
                            direction: Axis.horizontal,
                            // allowHalfRating: true,
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
                        // labelText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          // borderSide: BorderSide(
                          //   color: Colors.blue,
                          // ),
                        ),
                        hintText: '오늘 하루 어떠셨나요?',
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
  }

  Color? energyToColor(energy) {
    switch (energy.toInt()) {
      case 1:
        return Colors.lightGreen[100];
      case 2:
        return Colors.lightGreen[300];
      case 3:
        return Colors.lightGreen[500];
      case 4:
        return Colors.lightGreen[700];
      case 5:
        return Colors.lightGreen[900];
      default:
        return Colors.black;
    }
  }

  bool holidayPredicate(DateTime day, asyncSnapshot) {
    if (day.weekday == 7) {
      return true;
    } else if (asyncSnapshot.hasData) {
      return asyncSnapshot.data[DateFormat('yyyyMMdd').format(day)] != null;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isReTap) {
      setState(() {
        _focusedDay = getKoreanTime();
        widget.setReTapFalse();
      });
    }
    Future<Map<String, String>?> future() async {
      String solYear = '${_focusedDay.year}';
      String solMonth = '${_focusedDay.month}';
      if (solMonth.length == 1) {
        solMonth = '0$solMonth';
      }
      const serviceKey =
          'vGcOnDW+ywhtts/PnIk6QDB+J7JTcwVdOysxn74uzxJ6/TUtkKU5PHLf4z6yXJinJnU5qKALxEbYIz4WhemGQA==';
      var url = Uri.https('apis.data.go.kr',
          '/B090041/openapi/service/SpcdeInfoService/getRestDeInfo', {
        'solYear': solYear,
        'solMonth': solMonth,
        'ServiceKey': serviceKey,
        '_type': 'json'
      });

      /// http get 요청
      var response = await http.get(url);

      /// parsing
      /// 한글 변환을 위해 utf8.decode 사용
      final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
      final body = decodedData['response']['body'];
      final totalCount = body['totalCount'];
      final items = body['items'];

      if (items != '') {
        Map<String, String> parsedData = {};
        var item = items['item'];
        if (totalCount == 1) {
          item = items['item'];
          parsedData[item['locdate'].toString()] = item['dateName'];
        } else if (totalCount > 1) {
          final item = items['item'];
          for (var row in item) {
            parsedData[row['locdate'].toString()] = row['dateName'];
          }
        }
        return parsedData;
      } else {
        return null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            "현재시간: ${DateFormat('yyyy-MM-dd hh:mm').format(getKoreanTime())}"),
      ),
      body: isLoading
          ? const Scaffold()
          : Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Container(
                      decoration: borderForDebug,
                      padding: const EdgeInsets.fromLTRB(30, 0, 0, 0),
                      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                      height: 50,
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                          key: sfDateRangePickerKey,
                          child: Text(
                            '${_focusedDay.year}년 ${_focusedDay.month}월',
                            style: const TextStyle(
                                fontSize: 22, color: Colors.black),
                          ),
                          onPressed: () {
                            /// 버튼의 위치를 구함
                            final RenderBox sfDateRangePickerButton =
                                sfDateRangePickerKey.currentContext!
                                    .findRenderObject() as RenderBox;
                            final RenderBox overlay = Overlay.of(context)
                                .context
                                .findRenderObject() as RenderBox;
                            final buttonPosition = sfDateRangePickerButton
                                .localToGlobal(Offset.zero, ancestor: overlay);
                            showDialog<Widget>(
                                context: context,
                                builder: (BuildContext context) {
                                  return Transform.translate(
                                    offset: Offset(
                                        buttonPosition.dx,
                                        buttonPosition.dy +
                                            sfDateRangePickerButton
                                                .size.height),
                                    child: Dialog(
                                      /// insetPadding 설정으로 padding을 0으로 만들고 align을 topLeft로 설정해서
                                      /// 왼쪽 상단 모서리에서 dialog가 나타나게 셋팅
                                      insetPadding: const EdgeInsets.symmetric(
                                          horizontal: 0, vertical: 0),
                                      alignment: Alignment.topLeft,

                                      /// dialog의 크기를 제한
                                      /// width는 일정 크기 이상 작아지면 SfDateRangePicker의 min width의 영향으로
                                      /// 최소 크기에서 작아지지 않음
                                      child: SizedBox(
                                        height: 180,

                                        /// 최소 크기로 설정
                                        width: 0,
                                        child: SfDateRangePicker(
                                          showNavigationArrow: true,
                                          view: DateRangePickerView.year,
                                          selectionMode:
                                              DateRangePickerSelectionMode
                                                  .single,
                                          onViewChanged: (args) => {
                                            if (args.view ==
                                                DateRangePickerView.month)
                                              {
                                                Navigator.of(context).pop(),
                                                setState(() {
                                                  ///
                                                  _focusedDay = DateTime(
                                                      args.visibleDateRange
                                                          .endDate!.year,
                                                      args.visibleDateRange
                                                          .endDate!.month,
                                                      _focusedDay.day);
                                                })
                                              }
                                          },

                                          /// pick 가능한 최소, 최대 날짜 설정
                                          minDate: kFirstDay,
                                          maxDate: kLastDay,
                                        ),
                                      ),
                                    ),
                                  );
                                });
                          })),
                  Expanded(
                    child: Container(
                      decoration: borderForDebug,
                      child: FutureBuilder(
                          future: future(),
                          builder: (context, asyncSnapshot) {
                            return TableCalendar<Event>(
                              headerVisible: false,
                              shouldFillViewport: true,
                              holidayPredicate: (day) =>
                                  holidayPredicate(day, asyncSnapshot),
                              // 공휴일 표시
                              availableCalendarFormats: const {
                                CalendarFormat.month: '월',
                              },
                              locale: 'ko_KR',
                              rowHeight: 80,
                              daysOfWeekHeight: 30,
                              firstDay: kFirstDay,
                              lastDay: kLastDay,
                              focusedDay: _focusedDay,
                              // selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                              enabledDayPredicate: (day) =>
                                  getKoreanTime().compareTo(day) != -1,
                              // 날짜 비활성화
                              rangeStartDay: _rangeStart,
                              rangeEndDay: _rangeEnd,
                              calendarFormat: _calendarFormat,
                              rangeSelectionMode: _rangeSelectionMode,
                              eventLoader: _getEventsForDay,
                              startingDayOfWeek: snapshotValue['settings']
                                          ['startingDayOfWeek'] ==
                                      'monday'
                                  ? StartingDayOfWeek.monday
                                  : StartingDayOfWeek.sunday,
                              calendarStyle: const CalendarStyle(
                                  cellAlignment: Alignment.topCenter,
                                  holidayTextStyle:
                                      TextStyle(color: Colors.red),
                                  holidayDecoration: BoxDecoration(),
                                  selectedTextStyle: TextStyle(),
                                  selectedDecoration: BoxDecoration(),
                                  todayTextStyle: TextStyle(),
                                  todayDecoration: BoxDecoration(),
                                  tableBorder: TableBorder(
                                    horizontalInside:
                                        BorderSide(color: Colors.black12),
                                  )),
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
                                setState(() {
                                  _focusedDay = focusedDay;
                                });
                              },
                              calendarBuilders: CalendarBuilders(
                                headerTitleBuilder:
                                    (BuildContext context, DateTime day) {
                                  return Container(
                                    decoration: borderForDebug,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                            decoration: borderForDebug,
                                            child: TextButton(
                                                key: sfDateRangePickerKey,
                                                child: Text(
                                                  '${day.year}년 ${day.month}월',
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.black),
                                                ),
                                                onPressed: () {
                                                  /// 버튼의 위치를 구함
                                                  final RenderBox
                                                      sfDateRangePickerButton =
                                                      sfDateRangePickerKey
                                                              .currentContext!
                                                              .findRenderObject()
                                                          as RenderBox;
                                                  final RenderBox overlay =
                                                      Overlay.of(context)
                                                              .context
                                                              .findRenderObject()
                                                          as RenderBox;
                                                  final buttonPosition =
                                                      sfDateRangePickerButton
                                                          .localToGlobal(
                                                              Offset.zero,
                                                              ancestor:
                                                                  overlay);
                                                  showDialog<Widget>(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return Transform
                                                            .translate(
                                                          offset: Offset(
                                                              buttonPosition.dx,
                                                              buttonPosition
                                                                      .dy +
                                                                  sfDateRangePickerButton
                                                                      .size
                                                                      .height),
                                                          child: Dialog(
                                                            /// insetPadding 설정으로 padding을 0으로 만들고 align을 topLeft로 설정해서
                                                            /// 왼쪽 상단 모서리에서 dialog가 나타나게 셋팅
                                                            insetPadding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        0,
                                                                    vertical:
                                                                        0),
                                                            alignment: Alignment
                                                                .topLeft,

                                                            /// dialog의 크기를 제한
                                                            /// width는 일정 크기 이상 작아지면 SfDateRangePicker의 min width의 영향으로
                                                            /// 최소 크기에서 작아지지 않음
                                                            child: SizedBox(
                                                              height: 180,
                                                              width: 0,
                                                              child:
                                                                  SfDateRangePicker(
                                                                view:
                                                                    DateRangePickerView
                                                                        .year,
                                                                selectionMode:
                                                                    DateRangePickerSelectionMode
                                                                        .single,
                                                                onViewChanged:
                                                                    (args) => {
                                                                  if (args.view ==
                                                                      DateRangePickerView
                                                                          .month)
                                                                    {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop(),
                                                                      setState(
                                                                          () {
                                                                        ///
                                                                        _focusedDay = DateTime(
                                                                            args.visibleDateRange.endDate!.year,
                                                                            args.visibleDateRange.endDate!.month,
                                                                            _focusedDay.day);
                                                                      })
                                                                    }
                                                                },

                                                                /// 오른쪽 상단 좌우 화살표
                                                                showNavigationArrow:
                                                                    true,

                                                                /// pick 가능한 최소, 최대 날짜 설정
                                                                minDate:
                                                                    kFirstDay,
                                                                maxDate:
                                                                    kLastDay,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      });
                                                })),
                                      ],
                                    ),
                                  );
                                },
                                markerBuilder: (context, day, events) {
                                  final key =
                                      DateFormat('yyyyMMdd').format(day);

                                  Future<Map<dynamic, dynamic>?>
                                      future() async {
                                    DataSnapshot snapshot =
                                        await ref.child(key).get();

                                    if (snapshot.exists) {
                                      return snapshot.value
                                          as Map<dynamic, dynamic>;
                                    } else {
                                      return null;
                                    }
                                  }

                                  return FutureBuilder(
                                      future: future(),
                                      builder: (context, asyncSnapshot) {
                                        String? wakeupTime;
                                        String? bedTime;
                                        double? energy;
                                        String? memo;

                                        /// DB 데이터 가져옴
                                        if (asyncSnapshot.hasData) {
                                          wakeupTime =
                                              asyncSnapshot.data?["wakeupTime"];
                                          bedTime =
                                              asyncSnapshot.data?["bedTime"];
                                          energy = asyncSnapshot.data?["energy"]
                                              .toDouble();
                                          // if (energy is int) {
                                          //   energy = energy.toDouble();
                                          // }
                                          memo = asyncSnapshot.data?["memo"];
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Container(
                                            decoration: borderForDebug,
                                            child: Column(
                                              children: [
                                                Container(
                                                    decoration: borderForDebug,
                                                    height: 23,
                                                    child: DateFormat(
                                                                    'yyyyMMdd')
                                                                .format(day) ==
                                                            DateFormat(
                                                                    'yyyyMMdd')
                                                                .format(DateTime
                                                                    .now())
                                                        ? Stack(
                                                            children: [
                                                              Container(
                                                                decoration:
                                                                    const BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  // border: Border.all(
                                                                  //     width: 1,
                                                                  //     color: Colors
                                                                  //         .blue),
                                                                  color: Colors
                                                                      .blue,
                                                                ),
                                                              ),
                                                              // const Positioned(
                                                              //   top: 2,
                                                              //     left: 12,
                                                              //     child: Text(
                                                              //         '21', style: TextStyle(color: Colors
                                                              //               .white),))
                                                              Center(
                                                                  child: Text(
                                                                '${getKoreanTime().day}',
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ))
                                                            ],
                                                          )
                                                        : Container()),
                                                Expanded(
                                                  child: Container(
                                                    decoration: borderForDebug,
                                                    // width: MediaQuery.of(context).size.width * 0.2,
                                                    // padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.035),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        if (bedTime != null)
                                                          Container(
                                                            decoration:
                                                                borderForDebug,
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Container(
                                                                  decoration:
                                                                      borderForDebug,
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Container(
                                                                        decoration:
                                                                            borderForDebug,
                                                                        child:
                                                                            const Icon(
                                                                          Icons
                                                                              .nightlight_round_rounded,
                                                                          color:
                                                                              Colors.indigo,
                                                                          size:
                                                                              9,
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        decoration:
                                                                            borderForDebug,
                                                                        child:
                                                                            Text(
                                                                          bedTime,
                                                                          style:
                                                                              const TextStyle(
                                                                            color:
                                                                                Colors.black,
                                                                            fontSize:
                                                                                9,
                                                                          ),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        if (wakeupTime != null)
                                                          Container(
                                                            decoration:
                                                                borderForDebug,
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Container(
                                                                  decoration:
                                                                      borderForDebug,
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Container(
                                                                        decoration:
                                                                            borderForDebug,
                                                                        child:
                                                                            const Icon(
                                                                          Icons
                                                                              .sunny,
                                                                          color:
                                                                              Colors.yellow,
                                                                          size:
                                                                              9,
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        decoration:
                                                                            borderForDebug,
                                                                        child:
                                                                            Text(
                                                                          wakeupTime,
                                                                          style:
                                                                              const TextStyle(
                                                                            color:
                                                                                Colors.black,
                                                                            fontSize:
                                                                                9,
                                                                          ),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        if (memo != null)
                                                          Container(
                                                            decoration:
                                                                borderForDebug,
                                                            child: Row(
                                                              children: [
                                                                /// Expanded 2개 배치 시 공간을 정확히 반으로 분배
                                                                Expanded(
                                                                  child:
                                                                      Container(
                                                                    decoration:
                                                                        borderForDebug,
                                                                    child: Icon(
                                                                      Icons
                                                                          .circle,
                                                                      size: 8,
                                                                      color: energyToColor(
                                                                          energy),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child: Container(
                                                                      decoration: borderForDebug,
                                                                      child:

                                                                          /// 공백만으로 이루어진 문자는 메모가 없는 것으로 간주
                                                                          memo.replaceAll(' ', '') != ''
                                                                              ? Container(
                                                                                  decoration: borderForDebug,
                                                                                  child: const Icon(
                                                                                    Icons.comment_outlined,
                                                                                    color: Colors.red,
                                                                                    size: 8,
                                                                                  ),
                                                                                )
                                                                              : null),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        // Row(
                                                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        //   children: [
                                                        //     RatingBar.builder(
                                                        //       ignoreGestures: true,
                                                        //       initialRating: energy,
                                                        //       minRating: 1,
                                                        //       direction: Axis.horizontal,
                                                        //       allowHalfRating: true,
                                                        //       itemCount: 5,
                                                        //       itemPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                                                        //       itemBuilder: (context, _) => Icon(
                                                        //         // Image.asset(name),
                                                        //         Icons.rectangle_rounded,
                                                        //         color: G_energyColor,
                                                        //       ),
                                                        //       onRatingUpdate: (rating) {
                                                        //       },
                                                        //       itemSize: MediaQuery.of(context).size.height * 0.01
                                                        //     )
                                                        //   ],
                                                        // ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      });
                                },
                                dowBuilder: (context, day) {
                                  return null;
                                },
                                defaultBuilder: (context, day, focusedDay) {
                                  return null;
                                },
                              ),
                              onDayLongPressed: (DateTime selectedDay,
                                  DateTime focusedDay) async {},
                            );
                          }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
