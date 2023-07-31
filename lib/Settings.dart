import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'globalVariables.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
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
              child: const Icon(Icons.check, size: 30,),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(String type) {
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
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (type == '기상') {
                    G_wakeUpColor = Color(0xFFF8DAA0);
                  } else if (type == '취침') {
                    G_sleepColor = Colors.indigo;
                  } else if (type == '에너지') {
                    G_energyColor = Colors.green;
                  }
                });
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Widget widgetSetColor (String type) {
    Color color = Colors.black;
    if (type == '기상') {
      color = G_wakeUpColor;
    } else if (type == '취침') {
      color = G_sleepColor;
    } else if (type == '에너지') {
      color = G_energyColor;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(type, style: TextStyle(fontSize: 30),),
        const SizedBox(width: 30,),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(50, 50),
            backgroundColor: color,
            shape: const CircleBorder(), // 원 모양으로 버튼 꾸미기
            // padding: EdgeInsets.all(16), // 버튼 안의 컨텐츠(아이콘) 패딩 설정
          ),
          onPressed: () {
            _openColorPicker(type);
          },
          child: const Text(''),
        ),
        const SizedBox(width: 30,),
        TextButton(
          onPressed: () {
            _showConfirmationDialog(type);
          },
          child: const Text('기본값으로 변경'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      margin: const EdgeInsets.all(50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: const [
              Text("색상 변경", style: TextStyle(fontSize: 40),)
            ]
          ),
          widgetSetColor('기상'),
          widgetSetColor('취침'),
          widgetSetColor('에너지'),
        ],
      ),
    );
  }
}