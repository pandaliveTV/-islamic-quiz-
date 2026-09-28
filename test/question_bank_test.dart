import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:islamicquiz/data/models.dart';
import 'package:islamicquiz/data/question_repository.dart';

/// Validates the bundled question bank (assets/questions/*.json).
void main() {
  final bank = <String, List<Question>>{
    for (final c in categories)
      c.id: QuestionRepository.parse(File(c.asset).readAsStringSync()),
  };

  test('has at least 1000 questions in total', () {
    final total = bank.values.fold<int>(0, (a, l) => a + l.length);
    expect(total, greaterThanOrEqualTo(1000));
  });

  for (final c in categories) {
    group(c.title, () {
      final qs = bank[c.id]!;

      test('splits into full stages of 10', () {
        expect(qs.length, greaterThanOrEqualTo(150));
        expect(qs.length % QuestionRepository.stageSize, 0);
      });

      test('every question is well formed', () {
        for (final q in qs) {
          final label = q.text;
          expect(q.text.trim(), isNotEmpty, reason: label);
          expect(q.correct.trim(), isNotEmpty, reason: label);
          expect(q.explanation.trim(), isNotEmpty, reason: label);
          expect(q.wrong, hasLength(3), reason: label);
          for (final w in q.wrong) {
            expect(w.trim(), isNotEmpty, reason: label);
          }
          final options = {q.correct, ...q.wrong};
          expect(options, hasLength(4), reason: 'duplicate option: $label');
        }
      });

      test('has no duplicate questions', () {
        final texts = qs.map((q) => q.text).toList();
        expect(texts.toSet(), hasLength(texts.length));
      });
    });
  }
}
