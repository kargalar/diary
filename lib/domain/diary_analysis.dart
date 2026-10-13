import 'diary_entry.dart';

class DiaryAnalysis {
  DiaryAnalysis(List<DiaryEntry> allEntries, {required this.now, this.days})
    : allEntries = List.unmodifiable(allEntries) {
    final today = _dateOnly(now);
    final start = days == null
        ? null
        : today.subtract(Duration(days: days! - 1));
    entries = List.unmodifiable(
      allEntries.where(
        (entry) => start == null || !_dateOnly(entry.createdAt).isBefore(start),
      ),
    );
    previousEntries = days == null
        ? const []
        : List.unmodifiable(
            allEntries.where((entry) {
              final date = _dateOnly(entry.createdAt);
              final previousStart = start!.subtract(Duration(days: days!));
              return !date.isBefore(previousStart) && date.isBefore(start);
            }),
          );
  }

  final DateTime now;
  final int? days;
  final List<DiaryEntry> allEntries;
  late final List<DiaryEntry> entries;
  late final List<DiaryEntry> previousEntries;

  double get averageRating => _averageRating(entries);

  double? get ratingChange => previousEntries.isEmpty
      ? null
      : averageRating - _averageRating(previousEntries);

  Map<Mood, int> get moodCounts => _counts(entries.map((entry) => entry.mood));

  Map<int, int> get ratingCounts => {
    for (var rating = 1; rating <= 5; rating++)
      rating: entries.where((entry) => entry.rating == rating).length,
  };

  List<PersonAnalysis> get people {
    final entriesByPerson = <String, List<DiaryEntry>>{};
    for (final entry in entries) {
      for (final person in entry.people) {
        entriesByPerson.putIfAbsent(person, () => []).add(entry);
      }
    }
    return entriesByPerson.entries.map((item) {
      final moods = _counts(item.value.map((entry) => entry.mood));
      return PersonAnalysis(
        name: item.key,
        entryCount: item.value.length,
        averageRating: _averageRating(item.value),
        topMood: _topEntry(moods)?.key,
      );
    }).toList()..sort((a, b) => b.entryCount.compareTo(a.entryCount));
  }

  List<WeekdayAnalysis> get weekdays => [
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
      WeekdayAnalysis(
        weekday: weekday,
        entries: entries.where((entry) => entry.createdAt.weekday == weekday),
      ),
  ];

  int get currentStreak {
    final dates = _entryDates(allEntries);
    var date = _dateOnly(now);
    if (!dates.contains(date)) date = date.subtract(const Duration(days: 1));
    var streak = 0;
    while (dates.contains(date)) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    final dates = _entryDates(allEntries).toList()..sort();
    var longest = 0;
    var current = 0;
    DateTime? previous;
    for (final date in dates) {
      current = previous != null && date.difference(previous).inDays == 1
          ? current + 1
          : 1;
      if (current > longest) longest = current;
      previous = date;
    }
    return longest;
  }

  int get daysWrittenThisMonth => _entryDates(
    allEntries,
  ).where((date) => date.year == now.year && date.month == now.month).length;

  int? get mostActiveWeekday {
    final counts = _counts(allEntries.map((entry) => entry.createdAt.weekday));
    return _topEntry(counts)?.key;
  }

  double get averageWordCount => _averageWordCount(entries);

  double? get wordCountChange => previousEntries.isEmpty
      ? null
      : averageWordCount - _averageWordCount(previousEntries);

  DiaryEntry? get longestEntry => entries.isEmpty
      ? null
      : entries.reduce(
          (a, b) => _wordCount(a.body) >= _wordCount(b.body) ? a : b,
        );

  List<WordFrequency> get topWords {
    final counts = <String, int>{};
    for (final entry in entries) {
      for (final word in _words('${entry.title} ${entry.body}')) {
        if (word.length < 3 || _stopWords.contains(word)) continue;
        counts.update(word, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        return count != 0 ? count : a.key.compareTo(b.key);
      });
    return ranked
        .take(10)
        .map((item) => WordFrequency(item.key, item.value))
        .toList();
  }

  List<TrendPoint> get trend {
    if (entries.isEmpty) return const [];
    final sorted = [...entries]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final first = _dateOnly(sorted.first.createdAt);
    final span = _dateOnly(sorted.last.createdAt).difference(first).inDays + 1;
    final bucketDays = days != null && days! <= 30
        ? 1
        : (span / 12).ceil().clamp(1, 30);
    final groups = <int, List<DiaryEntry>>{};
    for (final entry in sorted) {
      final bucket =
          _dateOnly(entry.createdAt).difference(first).inDays ~/ bucketDays;
      groups.putIfAbsent(bucket, () => []).add(entry);
    }
    return groups.entries
        .map(
          (group) => TrendPoint(
            first.add(Duration(days: group.key * bucketDays)),
            _averageRating(group.value),
          ),
        )
        .toList();
  }
}

class PersonAnalysis {
  const PersonAnalysis({
    required this.name,
    required this.entryCount,
    required this.averageRating,
    required this.topMood,
  });

  final String name;
  final int entryCount;
  final double averageRating;
  final Mood? topMood;
}

class WeekdayAnalysis {
  WeekdayAnalysis({
    required this.weekday,
    required Iterable<DiaryEntry> entries,
  }) : entryCount = entries.length,
       averageRating = entries.isEmpty ? 0 : _averageRating(entries);

  final int weekday;
  final int entryCount;
  final double averageRating;
}

class WordFrequency {
  const WordFrequency(this.word, this.count);

  final String word;
  final int count;
}

class TrendPoint {
  const TrendPoint(this.date, this.averageRating);

  final DateTime date;
  final double averageRating;
}

double _averageRating(Iterable<DiaryEntry> entries) => entries.isEmpty
    ? 0
    : entries.fold<int>(0, (sum, entry) => sum + entry.rating) / entries.length;

double _averageWordCount(Iterable<DiaryEntry> entries) => entries.isEmpty
    ? 0
    : entries.fold<int>(0, (sum, entry) => sum + _wordCount(entry.body)) /
          entries.length;

int _wordCount(String text) => _words(text).length;

List<String> _words(String text) => RegExp(
  r"[a-zA-ZÀ-ÖØ-öø-ÿĞğİıŞşÇç]+",
).allMatches(text.toLowerCase()).map((match) => match.group(0)!).toList();

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

Set<DateTime> _entryDates(Iterable<DiaryEntry> entries) => {
  for (final entry in entries) _dateOnly(entry.createdAt),
};

MapEntry<T, int>? _topEntry<T>(Map<T, int> counts) => counts.entries.isEmpty
    ? null
    : counts.entries.reduce((a, b) => a.value >= b.value ? a : b);

Map<T, int> _counts<T>(Iterable<T> values) {
  final counts = <T, int>{};
  for (final value in values) {
    counts.update(value, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

const _stopWords = {
  'ama',
  'and',
  'are',
  'bir',
  'bu',
  'çok',
  'da',
  'daha',
  'de',
  'diye',
  'for',
  'gibi',
  'ile',
  'için',
  'ise',
  'that',
  'the',
  'this',
  'was',
  'were',
  've',
  'veya',
  'with',
  'you',
  'ben',
  'beni',
  'bana',
  'biz',
  'her',
  'şey',
  'sonra',
  'today',
  'had',
  'have',
  'has',
  'not',
  'but',
  'from',
  'they',
  'their',
  'there',
};
