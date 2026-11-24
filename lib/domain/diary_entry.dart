enum Mood {
  disappointed,
  sick,
  depressed,
  angry,
  anxious,
  tired,
  neutral,
  calm,
  happy,
  excited,
}

enum EntryCategory { diary, dream }

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.mood,
    required this.rating,
    required this.people,
    this.category = EntryCategory.diary,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final Mood mood;
  final int rating;
  final List<String> people;
  final EntryCategory category;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    mood: _moodFromJson(json['mood'] as String),
    rating: json['rating'] as int,
    people: List<String>.from(json['people'] as List),
    category: json['category'] == EntryCategory.dream.name
        ? EntryCategory.dream
        : EntryCategory.diary,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'mood': mood.name,
    'rating': rating,
    'people': people,
    'category': category.name,
  };
}

Mood _moodFromJson(String value) {
  return switch (value) {
    'awful' => Mood.depressed,
    'low' => Mood.disappointed,
    'okay' => Mood.neutral,
    'good' => Mood.calm,
    'great' => Mood.happy,
    _ => Mood.values.byName(value),
  };
}
