import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:islamicquiz/data/models.dart';
import 'package:islamicquiz/game/quiz_session.dart';

List<Question> makeQuestions(int n) => [
  for (var i = 0; i < n; i++)
    Question(
      text: 'q$i',
      correct: 'c$i',
      wrong: ['a$i', 'b$i', 'd$i'],
      explanation: 'e$i',
    ),
];

String wrongOf(StageSession s) =>
    s.options.firstWhere((o) => o != s.current.correct);

void main() {
  group('Rules.starsFor', () {
    test('maps mistakes to stars', () {
      expect(Rules.starsFor(0), 3);
      expect(Rules.starsFor(1), 2);
      expect(Rules.starsFor(2), 1);
      expect(Rules.starsFor(5), 1);
    });
  });

  group('StageSession', () {
    late StageSession s;
    setUp(() => s = StageSession(makeQuestions(10), rng: Random(1)));

    test('shuffles four options that include the correct one', () {
      expect(s.options, hasLength(4));
      expect(s.options, contains(s.current.correct));
    });

    test('perfect run gives 3 stars and bonus coins', () {
      for (var i = 0; i < 10; i++) {
        expect(s.answer(s.current.correct), isTrue);
        s.next();
      }
      expect(s.completed, isTrue);
      expect(s.stars, 3);
      expect(
        s.coinsEarned,
        10 * Rules.coinsPerCorrect + 3 * Rules.coinsPerStar,
      );
    });

    test('ignores a second answer to the same question', () {
      s.answer(s.current.correct);
      expect(s.answer(wrongOf(s)), isFalse);
      expect(s.mistakes, 0);
    });

    test('one and two mistakes give 2 and 1 stars', () {
      StageSession run(int mistakes) {
        final r = StageSession(makeQuestions(10), rng: Random(2));
        for (var i = 0; i < 10; i++) {
          r.answer(i < mistakes ? wrongOf(r) : r.current.correct);
          r.next();
        }
        return r;
      }

      expect(run(1).stars, 2);
      expect(run(2).stars, 1);
    });

    test('three mistakes lose the stage, revive once', () {
      for (var i = 0; i < 3; i++) {
        s.answer(wrongOf(s));
        if (i < 2) s.next();
      }
      expect(s.failed, isTrue);
      expect(s.stars, 0);
      expect(s.missed, hasLength(3));

      s.next(); // blocked while failed
      expect(s.index, 2);

      expect(s.canRevive, isTrue);
      s.revive();
      expect(s.failed, isFalse);
      expect(s.lives, 1);
      expect(s.canRevive, isFalse);

      s.next();
      s.answer(wrongOf(s));
      expect(s.failed, isTrue);
      expect(s.canRevive, isFalse);
    });

    test('fifty-fifty removes two wrong options only, once', () {
      expect(s.useFiftyFifty(), isTrue);
      expect(s.removed, hasLength(2));
      expect(s.removed, isNot(contains(s.current.correct)));
      expect(s.useFiftyFifty(), isFalse);
      // A removed option can't be picked.
      expect(s.answer(s.removed.first), isFalse);
      expect(s.answered, isFalse);
      s.next(); // not answered yet: stays
      expect(s.index, 0);
    });

    test('hint resets on the next question', () {
      s.useFiftyFifty();
      s.answer(s.current.correct);
      s.next();
      expect(s.hintUsed, isFalse);
      expect(s.picked, isNull);
    });
  });

  group('TimeChallengeSession', () {
    late TimeChallengeSession s;
    setUp(() => s = TimeChallengeSession(makeQuestions(5), rng: Random(3)));

    test('counts down and stops at zero', () {
      expect(s.remaining, const Duration(seconds: Rules.challengeSeconds));
      s.tick(const Duration(seconds: 59));
      expect(s.timeUp, isFalse);
      s.tick(const Duration(seconds: 5));
      expect(s.timeUp, isTrue);
      expect(s.remaining, Duration.zero);
    });

    test('scores correct answers and cycles through the pool', () {
      for (var i = 0; i < 7; i++) {
        s.answer(s.current.correct);
        s.next();
      }
      expect(s.score, 7);
      expect(s.coinsEarned, 7 * Rules.coinsPerCorrect);
    });

    test('no new question after time is up; revive adds time once', () {
      s.answer(s.current.correct);
      s.tick(const Duration(minutes: 2));
      final q = s.current;
      s.next();
      expect(s.current, same(q));

      expect(s.canRevive, isTrue);
      s.revive();
      expect(s.remaining, const Duration(seconds: Rules.reviveSeconds));
      expect(s.answered, isFalse);
      expect(s.canRevive, isFalse);
    });
  });
}
