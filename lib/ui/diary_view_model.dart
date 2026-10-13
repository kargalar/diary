import 'package:flutter/foundation.dart';

import '../data/diary_repository.dart';
import '../domain/diary_entry.dart';

class DiaryViewModel extends ChangeNotifier {
  DiaryViewModel(this._repository);

  final DiaryRepository _repository;
  final List<DiaryEntry> _entries = [];

  List<DiaryEntry> get entries => List.unmodifiable(_entries);

  List<String> get people =>
      {for (final entry in _entries) ...entry.people}.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  Future<void> load() async {
    _entries
      ..clear()
      ..addAll(await _repository.load());
    _sort();
    notifyListeners();
  }

  Future<void> add(DiaryEntry entry) async {
    _entries.add(entry);
    _sort();
    await _repository.save(_entries);
    notifyListeners();
  }

  Future<void> update(DiaryEntry entry) async {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index == -1) return;
    _entries[index] = entry;
    _sort();
    await _repository.save(_entries);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    await _repository.save(_entries);
    notifyListeners();
  }

  void _sort() => _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
