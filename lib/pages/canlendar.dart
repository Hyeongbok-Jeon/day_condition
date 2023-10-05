import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../utils.dart';
import '../globalVariables.dart';
import 'package:day_condition/models/holiday.dart';

class Canlendar extends StatefulWidget {
  Canlendar({Key? key, required this.useLightMode, required this.isReTap}) : super(key: key);

  final bool useLightMode;
  late bool isReTap;

  void setReTapFalse() {
    isReTap = false;
  }

  @override
  State<Canlendar> createState() => _CanlendarState();
}

class _CanlendarState extends State<Canlendar> {
  final gUidRef = FirebaseDatabase.instance.ref('$G_uid');
  final holidayInfoRef = FirebaseDatabase.instance.ref('holidayInfo');
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = getKoreanTime();
  bool isSfDateRangePickerDialogOpen = false;
  final GlobalKey sfDateRangePickerButtonKey = GlobalKey();
  Map<String, dynamic> snapshot = {};
  Map<String, dynamic> holidaySnapshot = {};
  late Future<List<Holiday>> futureHoliday;

  @override
  void initState() {
    super.initState();

    gUidRef.onValue.listen((DatabaseEvent event) {
      setState(() {
        snapshot.clear();
        for (DataSnapshot child in event.snapshot.children) {
          snapshot['${child.key}'] = child.value;
        }
      });
    });

    futureHoliday = fetchHoliday();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<List<Holiday>> fetchHoliday() async {
    List<Holiday> holidayList = [];

    final holidayRef = FirebaseDatabase.instance.ref('holidayInfo');
    final snapshot = await holidayRef.get();
    if (snapshot.exists) {
      for (DataSnapshot child in snapshot.children) {
        holidayList.addAll(Holiday.holidayListfromDataSnapshot(child));
      }
    } else {
      if (kDebugMode) {
        print('No data available.');
      }
    }

    return holidayList;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setEvent(selectedDay);
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
    int wakeupTimeHH = 7;
    int bedTimeHH = 23;
    int wakeupTimeMM = 0;
    int bedTimeMM = 0;
    dynamic energy = 3.0;
    int timeDiff = 0;
    TextEditingController textEditingController = TextEditingController();
    final key = DateFormat('yyyyMMdd').format(selectedDay);

    /// DB 연동
    if (snapshot.isNotEmpty) {
      if (snapshot['data'] != null) {
        if (snapshot['data'][key] != null) {
          final value = snapshot['data'][key];
          wakeupTimeHH = int.parse(value['wakeupTime'].split(':')[0]);
          wakeupTimeMM = int.parse(value['wakeupTime'].split(':')[1]);
          bedTimeHH = int.parse(value['bedTime'].split(':')[0]);
          bedTimeMM = int.parse(value['bedTime'].split(':')[1]);
          energy = value['energy'].toDouble();
          textEditingController.text = value['memo'];
        }
      }
    }

    DateTime wakeupTime = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, wakeupTimeHH, wakeupTimeMM);
    DateTime bedTime = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, bedTimeHH, bedTimeMM);
    String dayOfWeek = getDayOfWeekInKorean(selectedDay.weekday);

    int dateCompareResult = wakeupTime.compareTo(bedTime);
    timeDiff = dateCompareResult == -1
        ? (24 * 60) - bedTime.difference(wakeupTime).inMinutes
        : wakeupTime.difference(bedTime).inMinutes;

    /// Don't use 'BuildContext's across async gaps. (Documentation)  Try rewriting the code to not reference the 'BuildContext'.
    /// 위 에러 해결 코드
    if (!mounted) return;

    showModalBottomSheet<void>(
      showDragHandle: true,

      /// modal 높이 조절을 위해서는 true로 설정
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Padding(
            padding: EdgeInsets.fromLTRB(30, 0, 30, 40 + MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: borderForDebug,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: borderForDebug,
                        width: 190,
                        child: Text(
                          DateFormat('M월 d일 $dayOfWeek').format(selectedDay),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: borderForDebug,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                decoration: borderForDebug,
                                child: IconButton(
                                  onPressed: () async => {
                                    await gUidRef.child('data/$key').remove().then((value) {
                                      Navigator.pop(context);
                                    })
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: borderForDebug,
                                child: IconButton(
                                  onPressed: () async => {
                                    await gUidRef.child('data').update({
                                      key: {
                                        'date': selectedDay.toString(),
                                        "wakeupTime": DateFormat('HH:mm').format(wakeupTime),
                                        "bedTime": DateFormat('HH:mm').format(bedTime),
                                        "energy": energy,
                                        "timeDiff": timeDiff,
                                        'memo': textEditingController.text,
                                      }
                                    }).then((value) {
                                      setState(() {
                                        Navigator.pop(context);
                                      });
                                    })
                                  },
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.blue,
                                  ),
                                  // child: const Text('완료', style: TextStyle(fontSize: 30),),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  StatefulBuilder(builder: (BuildContext context, StateSetter modalSetState) {
                    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Container(
                        decoration: borderForDebug,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: borderForDebug,
                              child: Icon(
                                Icons.nightlight_round_rounded,
                                color: const Color(0xFF28A0FF),
                                size: Theme.of(context).textTheme.headlineMedium?.fontSize,
                              ),
                            ),
                            Container(
                                decoration: borderForDebug,
                                child: TextButton(
                                  onPressed: () => _showDialog(
                                    CupertinoDatePicker(
                                      initialDateTime: bedTime,
                                      mode: CupertinoDatePickerMode.time,
                                      use24hFormat: true,
                                      onDateTimeChanged: (DateTime newDateTime) {
                                        modalSetState(() => bedTime = newDateTime);
                                      },
                                    ),
                                  ),
                                  child: Text(
                                    DateFormat('HH:mm').format(bedTime),
                                    style: TextStyle(fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize),
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
                              child: Icon(
                                Icons.sunny,
                                color: const Color(0xFFFFDFB0),
                                size: Theme.of(context).textTheme.headlineMedium?.fontSize,
                              ),
                            ),
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
                                    style: TextStyle(fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ]);
                  }),
                  Divider(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  // IconSelectorWidget(),
                  RatingBar.builder(
                    initialRating: energy,
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
                      energy = rating;
                    },
                    itemSize: 60,
                  ),
                  Divider(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      decoration: borderForDebug,
                      child: TextField(
                        maxLines: 3,
                        controller: textEditingController,
                        decoration: const InputDecoration(
                          // prefixIcon: const Icon(Icons.comment_outlined),
                          // suffixIcon: IconButton(
                          //   icon: const Icon(Icons.clear),
                          //   onPressed: () => textEditingController.clear(),
                          // ),
                          filled: true,
                          border: OutlineInputBorder(),
                          hintText: '오늘 하루 어떠셨나요?',
                        ),
                        onChanged: (value) {
                          textEditingController.text = value;
                        },
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
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

  bool holidayPredicate(DateTime day, AsyncSnapshot holidayAsyncSnapshot) {
    if (day.weekday == 7 && day.month == _focusedDay.month) {
      return true;
    } else if (holidayAsyncSnapshot.hasData) {
      bool isHoliday = false;
      List<Holiday> holidayList = holidayAsyncSnapshot.data;
      for (Holiday holiday in holidayList) {
        if (DateFormat('yyyyMMdd').format(day) == holiday.locdate) {
          isHoliday = true;
        }
      }
      return isHoliday;
    } else {
      return false;
    }
  }

  void showSfDateRangePickerDialog() async {
    /// 버튼의 위치를 구함
    final RenderBox sfDateRangePickerButton =
        sfDateRangePickerButtonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonPosition = sfDateRangePickerButton.localToGlobal(Offset.zero, ancestor: overlay);

    setState(() {
      isSfDateRangePickerDialogOpen = true;
    });

    /// await로 dialog가 닫힐 때 까지 코드
    await showDialog<Widget>(
        context: context,
        builder: (BuildContext context) {
          return Transform.translate(
            offset: Offset(buttonPosition.dx, buttonPosition.dy + sfDateRangePickerButton.size.height),
            child: Dialog(
              /// insetPadding 설정으로 padding을 0으로 만들고 align을 topLeft로 설정해서
              /// 왼쪽 상단 모서리에서 dialog가 나타나게 셋팅
              insetPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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
                  selectionMode: DateRangePickerSelectionMode.single,
                  onViewChanged: (args) => {
                    if (args.view == DateRangePickerView.month)
                      {
                        Navigator.of(context).pop(),
                        setState(() {
                          _focusedDay = DateTime(args.visibleDateRange.endDate!.year,
                              args.visibleDateRange.endDate!.month, _focusedDay.day);
                          isSfDateRangePickerDialogOpen = false;
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

    setState(() {
      isSfDateRangePickerDialogOpen = false; // 다이얼로그가 열릴 때 변수를 true로 설정
    });
  }

  List<Holiday> getHolidayList() {
    List<Holiday> holidayList = [];
    // holidayList.addAll(Holiday.holidayListfromJson(holidaySnapshot));
    return holidayList;
  }

  @override
  Widget build(BuildContext context) {
    /// bottom navigation 캘린더 아이콘 클릭 시 현재 날짜로 이동
    if (widget.isReTap) {
      _focusedDay = getKoreanTime();
      widget.setReTapFalse();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 110,
        child: Column(
          children: [
            Expanded(
              flex: 1,
              // decoration: borderForDebug,
              // height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.all(Colors.transparent),
                    ),
                    onPressed: showSfDateRangePickerDialog,
                    child: Row(
                      children: [
                        Container(
                          decoration: borderForDebug,
                          child: Text(
                            '${_focusedDay.year}.${_focusedDay.month}',
                            style: TextStyle(
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                                color: Theme.of(context).colorScheme.onBackground,
                                fontWeight: FontWeight.w900),
                            key: sfDateRangePickerButtonKey,
                          ),
                        ),
                        Container(
                          decoration: borderForDebug,
                          child: Icon(
                            isSfDateRangePickerDialogOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                            color: Theme.of(context).colorScheme.onBackground,
                            size: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 12,
                // height: MediaQuery.of(context).size.height * 0.85,
                // decoration: borderForDebug,
                child: snapshot['settings'] == null
                    ? const Center()
                    : FutureBuilder(
                        future: futureHoliday,
                        builder: (context, holidayAsyncSnapshot) {
                          return TableCalendar<Event>(
                            headerVisible: false,
                            shouldFillViewport: true,
                            holidayPredicate: (day) => holidayPredicate(day, holidayAsyncSnapshot),
                            // 공휴일 표시
                            availableCalendarFormats: const {
                              CalendarFormat.month: '월',
                            },
                            locale: 'ko_KR',
                            // rowHeight: 80,
                            daysOfWeekHeight: 30,
                            firstDay: kFirstDay,
                            lastDay: kLastDay,
                            focusedDay: _focusedDay,
                            // selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            // enabledDayPredicate: (day) => getKoreanTime().compareTo(day) != -1,
                            // 날짜 비활성화
                            calendarFormat: _calendarFormat,
                            startingDayOfWeek: snapshot['settings']['startingDayOfWeek'] == 'sunday'
                                ? StartingDayOfWeek.sunday
                                : StartingDayOfWeek.monday,
                            calendarStyle: CalendarStyle(
                              cellAlignment: Alignment.topCenter,
                              holidayTextStyle: TextStyle(
                                  color: Colors.red, fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize),
                              holidayDecoration: const BoxDecoration(),
                              selectedTextStyle: const TextStyle(),
                              selectedDecoration: const BoxDecoration(),
                              todayTextStyle: const TextStyle(),
                              todayDecoration: const BoxDecoration(),
                              tableBorder: TableBorder(
                                horizontalInside: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant),
                              ),
                              defaultTextStyle: TextStyle(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize),
                              weekendTextStyle: TextStyle(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize),
                              outsideTextStyle: TextStyle(
                                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                  color: Theme.of(context).colorScheme.surfaceVariant),
                              // outsideDaysVisible: true,
                              disabledTextStyle: TextStyle(
                                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                  color: Theme.of(context).colorScheme.surfaceVariant),
                              // disabledDecoration: const BoxDecoration(),
                            ),
                            onDaySelected: _onDaySelected,
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
                              headerTitleBuilder: (BuildContext context, DateTime day) {
                                return Container(
                                  decoration: borderForDebug,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                          decoration: borderForDebug,
                                          child: TextButton(
                                              key: sfDateRangePickerButtonKey,
                                              child: Text(
                                                '${day.year}년 ${day.month}월',
                                                style: TextStyle(
                                                    fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                                                    color: Colors.black),
                                              ),
                                              onPressed: () {
                                                /// 버튼의 위치를 구함
                                                final RenderBox sfDateRangePickerButton =
                                                    sfDateRangePickerButtonKey.currentContext!.findRenderObject()
                                                        as RenderBox;
                                                final RenderBox overlay =
                                                    Overlay.of(context).context.findRenderObject() as RenderBox;
                                                final buttonPosition =
                                                    sfDateRangePickerButton.localToGlobal(Offset.zero, ancestor: overlay);
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return Transform.translate(
                                                        offset: Offset(buttonPosition.dx,
                                                            buttonPosition.dy + sfDateRangePickerButton.size.height),
                                                        child: Dialog(
                                                          /// insetPadding 설정으로 padding을 0으로 만들고 align을 topLeft로 설정해서
                                                          /// 왼쪽 상단 모서리에서 dialog가 나타나게 셋팅
                                                          insetPadding:
                                                              const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                                          alignment: Alignment.topLeft,

                                                          /// dialog의 크기를 제한
                                                          /// width는 일정 크기 이상 작아지면 SfDateRangePicker의 min width의 영향으로
                                                          /// 최소 크기에서 작아지지 않음
                                                          child: SizedBox(
                                                            height: 180,
                                                            width: 0,
                                                            child: SfDateRangePicker(
                                                              view: DateRangePickerView.year,
                                                              selectionMode: DateRangePickerSelectionMode.single,
                                                              onViewChanged: (args) => {
                                                                if (args.view == DateRangePickerView.month)
                                                                  {
                                                                    Navigator.of(context).pop(),
                                                                    setState(() {
                                                                      ///
                                                                      _focusedDay = DateTime(
                                                                          args.visibleDateRange.endDate!.year,
                                                                          args.visibleDateRange.endDate!.month,
                                                                          _focusedDay.day);
                                                                    })
                                                                  }
                                                              },

                                                              /// 오른쪽 상단 좌우 화살표
                                                              showNavigationArrow: true,

                                                              /// pick 가능한 최소, 최대 날짜 설정
                                                              minDate: kFirstDay,
                                                              maxDate: kLastDay,
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
                                final key = DateFormat('yyyyMMdd').format(day);

                                String? wakeupTime;
                                String? bedTime;
                                double? energy;
                                String? memo;

                                /// DB 연동
                                if (snapshot.isNotEmpty) {
                                  if (snapshot['data'] != null) {
                                    if (snapshot['data'][key] != null) {
                                      final value = snapshot['data'][key];
                                      wakeupTime = value['wakeupTime'];
                                      bedTime = value['bedTime'];
                                      energy = value['energy'].toDouble();
                                      memo = value['memo'];
                                    }
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    decoration: borderForDebug,
                                    child: Stack(
                                      children: [
                                        DateFormat('yyyyMMdd').format(day) ==
                                                DateFormat('yyyyMMdd').format(getKoreanTime())
                                            ? Container(
                                                height: 23,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.blue,
                                                ),
                                              )
                                            : Container(),
                                        Column(
                                          children: [
                                            Container(
                                                decoration: borderForDebug,
                                                height: 23,
                                                child: DateFormat('yyyyMMdd').format(day) ==
                                                        DateFormat('yyyyMMdd').format(getKoreanTime())
                                                    ? Center(
                                                        child: Text(
                                                        '${getKoreanTime().day}',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize),
                                                      ))
                                                    : Container()),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  if (bedTime != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 5),
                                                      child: SizedBox(
                                                        height: 15,
                                                        // padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
                                                        child: Stack(alignment: Alignment.center, children: [
                                                          Container(
                                                            // color: Colors.indigo.shade400,
                                                            decoration: const BoxDecoration(
                                                              shape: BoxShape.rectangle,
                                                              color: Color(0xFF28A0FF),
                                                              borderRadius: BorderRadius.all(Radius.circular(2.0)),
                                                            ),
                                                          ),
                                                          Text(
                                                            bedTime,
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ]),
                                                      ),
                                                    ),
                                                  if (wakeupTime != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 5),
                                                      child: SizedBox(
                                                        height: 15,
                                                        // padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
                                                        child: Stack(alignment: Alignment.center, children: [
                                                          Container(
                                                            decoration: const BoxDecoration(
                                                              shape: BoxShape.rectangle,
                                                              color: Color(0xFFFFDFB0),
                                                              borderRadius: BorderRadius.all(Radius.circular(2.0)),
                                                            ),
                                                          ),
                                                          Text(
                                                            wakeupTime,
                                                            style: const TextStyle(
                                                              color: Colors.black,
                                                              fontSize: 10,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ]),
                                                      ),
                                                    ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 5),
                                                    child: Container(
                                                      decoration: borderForDebug,
                                                      height: 15,
                                                      child: Row(
                                                        children: [
                                                          /// Expanded 2개 배치 시 공간을 정확히 반으로 분배
                                                          Expanded(
                                                            child: energy != null
                                                                ? Container(
                                                                    decoration: borderForDebug,
                                                                    child: Icon(Icons.circle,
                                                                        color: energyToColor(energy), size: 10),
                                                                  )
                                                                : Container(),
                                                          ),
                                                          Expanded(
                                                            child: memo != null
                                                                ? Container(
                                                                    decoration: borderForDebug,
                                                                    child:

                                                                        /// 공백만으로 이루어진 문자는 메모가 없는 것으로 간주
                                                                        memo.replaceAll(' ', '') != ''
                                                                            ? Container(
                                                                                decoration: borderForDebug,
                                                                                child: const Icon(
                                                                                  Icons.comment_outlined,
                                                                                  color: Colors.red,
                                                                                  size: 10,
                                                                                ),
                                                                              )
                                                                            : null)
                                                                : Container(),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        })),
          ],
        ),
      ),
    );
  }
}
