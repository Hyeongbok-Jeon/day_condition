import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'globalVariables.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final ref = FirebaseDatabase.instance.ref('$G_uid');
  Map<dynamic, dynamic> snapshotValue = <dynamic, dynamic>{};
  String? startingDayOfWeek;

  @override
  void initState() {
    super.initState();

    final query = ref.child('/settings');
    query.onValue.listen((event) {
      if (mounted) {
        setState(() {
          for (final child in event.snapshot.children) {
            snapshotValue[child.key] = child.value;
          }
          startingDayOfWeek = snapshotValue['startingDayOfWeek'];
        });
      }
    });
  }

  // 색상 변경 다이얼로그 호출
  void _openColorPicker(String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: MaterialPicker(
              pickerColor: G_wakeUpColor,
              onColorChanged: (color) {
                setState(() {
                  if (type == '기상') {
                    G_wakeUpColor = color;
                  } else if (type == '취침') {
                    G_sleepColor = color;
                  } else if (type == '에너지') {
                    G_energyColor = color;
                  }
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Icon(
                Icons.check,
                size: 30,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(String? type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // title: Text('Confirmation'),
          content: const Text('기본값으로 변경하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                // '취소' 버튼을 눌렀을 때 실행되는 동작
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (type == '기상') {
                    G_wakeUpColor = const Color(0xFFF8DAA0);
                  } else if (type == '취침') {
                    G_sleepColor = Colors.indigo;
                  } else if (type == '에너지') {
                    G_energyColor = Colors.green;
                  }
                });
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Widget widgetSetColor(String type) {
    Color color = Colors.black;
    if (type == '기상') {
      color = G_wakeUpColor;
    } else if (type == '취침') {
      color = G_sleepColor;
    } else if (type == '에너지') {
      color = G_energyColor;
    }

    return Container(
      decoration: borderForDebug,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
              decoration: borderForDebug,
              width: 90,
              child: Center(
                  child: Text(
                type,
                style: const TextStyle(fontSize: 25),
              ))),
          Container(
            decoration: borderForDebug,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(40, 40),
                backgroundColor: color,
                shape: const CircleBorder(), // 원 모양으로 버튼 꾸미기
                // padding: EdgeInsets.all(16), // 버튼 안의 컨텐츠(아이콘) 패딩 설정
              ),
              onPressed: () {
                _openColorPicker(type);
              },
              child: const Text(''),
            ),
          ),
          Container(
            decoration: borderForDebug,
            child: TextButton(
              onPressed: () {
                _showConfirmationDialog(type);
              },
              child: const Text('기본값으로 변경'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("설정")),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              decoration: borderForDebug,
              height: 500,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                      alignment: AlignmentDirectional.topStart,
                      decoration: borderForDebug,
                      child: Text(
                        "색상",
                        style: TextStyle(fontSize: 30),
                      )),
                  widgetSetColor('기상'),
                  widgetSetColor('취침'),
                  widgetSetColor('에너지'),
                  Container(
                      decoration: borderForDebug,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                              child: const Text(
                            "시작 요일",
                            style: TextStyle(fontSize: 20),
                          )),
                          Row(
                            children: [
                              Container(
                                decoration: borderForDebug,
                                child: Row(
                                  children: [
                                    Container(
                                        decoration: borderForDebug,
                                        child: Text('월요일')),
                                    Container(
                                      decoration: borderForDebug,
                                      child: Radio(
                                        value: 'monday',
                                        groupValue: startingDayOfWeek,
                                        onChanged: (value) {
                                          setState(() {
                                            startingDayOfWeek = value;
                                            ref.child('settings').update({
                                              'startingDayOfWeek': value,
                                            });
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: borderForDebug,
                                child: Row(
                                  children: [
                                    Container(
                                        decoration: borderForDebug,
                                        child: Text('일요일')),
                                    Container(
                                      decoration: borderForDebug,
                                      child: Radio(
                                        value: 'sunday',
                                        groupValue: startingDayOfWeek,
                                        onChanged: (value) {
                                          setState(() {
                                            startingDayOfWeek = value;
                                            ref.child('settings').update({
                                              'startingDayOfWeek': value,
                                            });
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                  Container(
                    decoration: borderForDebug,
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              // title: Text('Confirmation'),
                              content: const Text('데이터를 초기화 하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    // '취소' 버튼을 눌렀을 때 실행되는 동작
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () async => {
                                    await ref.remove().then((value) {
                                      ref.child('settings').update(
                                          {'startingDayOfWeek': 'sunday'});
                                    }).then((value) {
                                      setState(() {
                                        Navigator.pop(context);
                                      });
                                    })
                                  },
                                  child: const Text('확인'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('데이터 초기화'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
