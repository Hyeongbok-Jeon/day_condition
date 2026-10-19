import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 공휴일 목록(`yyyyMMdd` → 이름).
///
/// 앱에 들어 있는 assets/holidays.json을 기본으로 쓰고, 실행할 때마다 GitHub에 올라간
/// 최신 파일을 받아 기기에 저장해 둔다. 이 파일은 매주 GitHub Actions가 갱신하므로
/// 임시공휴일이 새로 지정돼도 앱을 다시 배포하지 않고 반영된다.
class Holidays {
  static const _remoteUrl =
      'https://raw.githubusercontent.com/Hyeongbok-Jeon/day_condition/master/assets/holidays.json';
  static const _cacheKey = 'holidays_cache_v1';

  /// 저장해 둔 최신본이 있으면 그것을, 없으면 앱에 들어 있는 파일을 돌려준다.
  static Future<Map<String, String>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      final parsed = _parse(cached);
      if (parsed != null) return parsed;
    }
    return _parse(await rootBundle.loadString('assets/holidays.json')) ?? {};
  }

  /// 최신본을 받아 저장한다. 실패하면(오프라인 등) null.
  static Future<Map<String, String>?> refresh() async {
    try {
      final res = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = utf8.decode(res.bodyBytes);
      final parsed = _parse(body);
      if (parsed == null || parsed.isEmpty) return null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
      return parsed;
    } catch (e) {
      if (kDebugMode) print('Holiday refresh failed: $e');
      return null;
    }
  }

  static Map<String, String>? _parse(String json) {
    try {
      return Map<String, String>.from(jsonDecode(json) as Map);
    } catch (_) {
      return null;
    }
  }
}
