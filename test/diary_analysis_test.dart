import 'package:diary/domain/diary_analysis.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates period, habit, people, and word insights', () {
    final analysis = DiaryAnalysis(
      [
        _entry(
          '1',
          DateTime(2026, 9, 7),
          rating: 5,
          mood: Mood.happy,
          body: 'Coffee walk coffee with Ada',
          people: const ['Ada'],
        ),
        _entry(
          '2',
          DateTime(2026, 9, 6),
          rating: 3,
          mood: Mood.calm,
          body: 'Long walk and coffee',
          people: const ['Ada'],
        ),
        _entry(
          '3',
          DateTime(2026, 8, 8),
          rating: 2,
          mood: Mood.tired,
          body: 'Old entry',
        ),
      ],
      now: DateTime(2026, 9, 7),
      days: 30,
    );

    expect(analysis.entries, hasLength(2));
    expect(analysis.averageRating, 4);
    expect(analysis.ratingChange, 2);
    expect(analysis.currentStreak, 2);
    expect(analysis.longestStreak, 2);
    expect(analysis.daysWrittenThisMonth, 2);
    expect(analysis.people.single.averageRating, 4);
    expect(analysis.topWords.first.word, 'coffee');
    expect(analysis.topWords.first.count, 3);
  });
}

DiaryEntry _entry(
  String id,
  DateTime date, {
  required int rating,
  required Mood mood,
  required String body,
  List<String> people = const [],
}) => DiaryEntry(
  id: id,
  title: 'Day',
  body: body,
  createdAt: date,
  mood: mood,
  rating: rating,
  people: people,
);
