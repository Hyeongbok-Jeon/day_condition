import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 기록과 설정을 기기(웹은 브라우저)에 저장한다.
///
/// 저장 구조는 예전 Firebase 경로와 같다:
/// `{ 'settings': {...}, 'data': { 'yyyyMMdd': {...} } }`
class LocalStore extends ChangeNotifier {
  LocalStore._(this._prefs, this._root);

  static const _storageKey = 'day_condition_v1';
  static late LocalStore instance;

  final SharedPreferences _prefs;
  Map<String, dynamic> _root;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> root = {};
    final saved = prefs.getString(_storageKey);
    if (saved != null) {
      try {
        root = Map<String, dynamic>.from(jsonDecode(saved) as Map);
      } catch (e) {
        if (kDebugMode) print('Ignoring unreadable saved data: $e');
      }
    }
    instance = LocalStore._(prefs, root);
    instance._ensureDefaults();
  }

  /// 페이지들이 읽는 전체 스냅숏. 수정은 아래 메서드로만 한다.
  Map<String, dynamic> get snapshot => _root;

  Map<String, dynamic> get settings =>
      Map<String, dynamic>.from(_root['settings'] as Map);

  Map<String, dynamic> get data =>
      Map<String, dynamic>.from((_root['data'] as Map?) ?? {});

  Future<void> setEntry(String key, Map<String, dynamic> entry) {
    final data = this.data..[key] = entry;
    _root['data'] = data;
    return _save();
  }

  Future<void> removeEntry(String key) {
    final data = this.data..remove(key);
    _root['data'] = data;
    return _save();
  }

  Future<void> setSetting(String key, Object value) {
    _root['settings'] = settings..[key] = value;
    return _save();
  }

  Future<void> clear() {
    _root = {};
    _ensureDefaults();
    return _save();
  }

  /// 백업용 JSON 문자열.
  String exportJson() => jsonEncode(_root);

  /// 백업 JSON으로 전체를 교체한다. 형식이 틀리면 FormatException을 던진다.
  Future<void> importJson(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map || decoded['data'] is! Map) {
      throw const FormatException('백업 데이터 형식이 올바르지 않습니다.');
    }
    _root = Map<String, dynamic>.from(decoded);
    _ensureDefaults();
    return _save();
  }

  void _ensureDefaults() {
    final settings =
        Map<String, dynamic>.from((_root['settings'] as Map?) ?? {});
    settings['startingDayOfWeek'] ??= 'sunday';
    _root['settings'] = settings;
    _root['data'] ??= <String, dynamic>{};
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs.setString(_storageKey, jsonEncode(_root));
  }
}
