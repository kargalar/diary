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

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.mood,
    required this.rating,
    required this.people,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final Mood mood;
  final int rating;
  final List<String> people;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    mood: _moodFromJson(json['mood'] as String),
    rating: json['rating'] as int,
    people: List<String>.from(json['people'] as List),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'mood': mood.name,
    'rating': rating,
    'people': people,
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
