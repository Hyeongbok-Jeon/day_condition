import 'package:flutter/material.dart';

class IconSelectorWidget extends StatefulWidget {
  @override
  _IconSelectorWidgetState createState() => _IconSelectorWidgetState();
}

class _IconSelectorWidgetState extends State<IconSelectorWidget> {
  int selectedIconIndex = -1; // 선택한 아이콘의 인덱스, 초기에는 아무것도 선택되지 않음

  // 아이콘 목록
  final List<IconData> icons = [
    Icons.emoji_emotions,
    Icons.favorite,
    Icons.music_note,
    Icons.movie,
    Icons.sports,
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          icons.length,
              (index) => GestureDetector(
            onTap: () {
              setState(() {
                selectedIconIndex = index; // 아이콘을 선택하면 해당 인덱스로 설정
              });
            },
            child: Container(
              // padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: index == selectedIconIndex
                      ? Colors.blue // 선택한 아이콘은 파란색 테두리
                      : Colors.grey, // 선택하지 않은 아이콘은 회색 테두리
                ),
                // borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                icons[index],
                size: 35.0,
                color: index == selectedIconIndex
                    ? Colors.blue // 선택한 아이콘은 파란색
                    : Colors.white38, // 선택하지 않은 아이콘은 검은색
              ),
            ),
          ),
        ),
      ),
    );
  }
}