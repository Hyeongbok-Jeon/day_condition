import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../SingleChoice.dart';
import '../data/local_store.dart';
import '../globalVariables.dart';

class Settings extends StatefulWidget {
  const Settings({
    super.key,
    required this.useLightMode,
    required this.handleBrightnessChange,
  });

  final bool useLightMode;
  final Function(bool useLightMode) handleBrightnessChange;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Map<String, dynamic> snapshot = {};

  @override
  void initState() {
    super.initState();
    snapshot.addAll(LocalStore.instance.settings);
    LocalStore.instance.addListener(_sync);
  }

  @override
  void dispose() {
    LocalStore.instance.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    setState(() {
      snapshot
        ..clear()
        ..addAll(LocalStore.instance.settings);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 전체 기록을 JSON으로 클립보드에 복사한다. 메모나 메신저에 붙여 넣어 보관하면 된다.
  Future<void> _exportBackup() async {
    await Clipboard.setData(ClipboardData(text: LocalStore.instance.exportJson()));
    if (!mounted) return;
    _showMessage('백업 데이터를 클립보드에 복사했습니다. 메모 등에 붙여 넣어 보관하세요.');
  }

  Future<void> _importBackup() async {
    final controller = TextEditingController();
    final json = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('백업 불러오기'),
          content: TextField(
            controller: controller,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '보관해 둔 백업 데이터를 붙여 넣으세요.\n지금 기록은 모두 바뀝니다.',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('불러오기')),
          ],
        );
      },
    );
    if (json == null || json.trim().isEmpty) return;
    try {
      await LocalStore.instance.importJson(json.trim());
      if (!mounted) return;
      _showMessage('백업을 불러왔습니다.');
    } on FormatException {
      if (!mounted) return;
      _showMessage('백업 데이터 형식이 올바르지 않습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle =
        Theme.of(context).textTheme.apply(bodyColor: Theme.of(context).colorScheme.primary).titleMedium;
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                    decoration: borderForDebug,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "다크모드",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Switch(
                          value: !widget.useLightMode,
                          onChanged: (value) {
                            setState(() {
                              widget.handleBrightnessChange(!value);
                            });
                          },
                        ),
                      ],
                    )),
                Container(
                    decoration: borderForDebug,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "시작 요일",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SingleChoice(snapshot: snapshot),
                      ],
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(onPressed: _exportBackup, child: Text('백업 복사', style: linkStyle)),
                    TextButton(onPressed: _importBackup, child: Text('백업 불러오기', style: linkStyle)),
                  ],
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
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
                                onPressed: () async {
                                  await LocalStore.instance.clear();
                                  if (context.mounted) Navigator.pop(context);
                                },
                                child: const Text('확인'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text('데이터 초기화', style: linkStyle),
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
