import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../SingleChoice.dart';
import '../globalVariables.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final ref = FirebaseDatabase.instance.ref('$G_uid');
  Map<String, dynamic> snapshot = {};

  @override
  void initState() {
    super.initState();

    ref.child('settings').onValue.listen((DatabaseEvent event) {
      setState(() {
        snapshot.clear();
        for (DataSnapshot child in event.snapshot.children) {
          snapshot['${child.key}'] = child.value;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    decoration: borderForDebug,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          "시작 요일",
                          style: TextStyle(fontSize: 20),
                        ),
                        snapshot['startingDayOfWeek'] == null
                            ? const Center(
                              child: CircularProgressIndicator(),
                            )
                            : SingleChoice(snapshot: snapshot),
                      ],
                    )),
                const SizedBox(
                  height: 30,
                ),
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
                                    ref.child('settings').update({'startingDayOfWeek': 'sunday'});
                                  }).then((value) {
                                    Navigator.pop(context);
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
    );
  }
}
