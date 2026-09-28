import 'package:flutter/material.dart';

/// One question as stored in `assets/questions/<category>.json`:
/// `{"q": question, "c": correct answer, "w": [3 wrong answers], "e": note}`.
/// The correct answer is kept separate so options can be shuffled per play.
class Question {
  final String text;
  final String correct;
  final List<String> wrong;
  final String explanation;

  const Question({
    required this.text,
    required this.correct,
    required this.wrong,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    text: j['q'] as String,
    correct: j['c'] as String,
    wrong: (j['w'] as List).cast<String>(),
    explanation: j['e'] as String,
  );
}

class QuizCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  const QuizCategory(this.id, this.title, this.icon, this.color);

  String get asset => 'assets/questions/$id.json';
}

const categories = <QuizCategory>[
  QuizCategory('quran', 'القرآن الكريم', Icons.menu_book, Color(0xFF1B7F5B)),
  QuizCategory('seerah', 'السيرة النبوية', Icons.mosque, Color(0xFF2A6F97)),
  QuizCategory('sahaba', 'الصحابة', Icons.groups, Color(0xFF8C5E2A)),
  QuizCategory('fiqh', 'الفقه', Icons.balance, Color(0xFF6B4C9A)),
  QuizCategory('prophets', 'الأنبياء', Icons.auto_stories, Color(0xFF3E7C7B)),
  QuizCategory(
    'history',
    'التاريخ الإسلامي',
    Icons.account_balance,
    Color(0xFFA2463B),
  ),
];

QuizCategory categoryById(String id) =>
    categories.firstWhere((c) => c.id == id, orElse: () => categories.first);
