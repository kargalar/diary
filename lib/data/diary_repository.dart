import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/diary_entry.dart';

class DiaryRepository {
  static const _entriesKey = 'diary_entries';
  static const _darkThemeKey = 'diary_dark_theme';

  Future<bool> loadDarkTheme() async =>
      (await SharedPreferences.getInstance()).getBool(_darkThemeKey) ?? true;

  Future<void> saveDarkTheme(bool enabled) async {
    await (await SharedPreferences.getInstance()).setBool(
      _darkThemeKey,
      enabled,
    );
  }

  Future<List<DiaryEntry>> load() async {
    final data = (await SharedPreferences.getInstance()).getString(_entriesKey);
    if (data == null) return [];
    return (jsonDecode(data) as List)
        .map((item) => DiaryEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<DiaryEntry> entries) async {
    final data = jsonEncode(entries.map((entry) => entry.toJson()).toList());
    await (await SharedPreferences.getInstance()).setString(_entriesKey, data);
  }
}
