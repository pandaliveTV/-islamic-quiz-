import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models.dart';

/// Game tuning shared by both modes.
class Rules {
  static const lives = 3;
  static const coinsPerCorrect = 2;
  static const coinsPerStar = 5;
  static const hintCost = 20;
  static const challengeSeconds = 60;
  static const reviveSeconds = 15;

  /// 0 mistakes → 3 stars, 1 → 2 stars, more → 1 star (stage still passed).
  static int starsFor(int mistakes) => mistakes <= 0
      ? 3
      : mistakes == 1
      ? 2
      : 1;
}

/// Shared per-question state: shuffled options, the 50/50 hint and the
/// answer the player picked.
abstract class _QuestionFlow extends ChangeNotifier {
  final Random rng;
  _QuestionFlow(Random? rng) : rng = rng ?? Random();

  Question get current;

  late List<String> options;
  final removed = <String>{};
  String? picked;
  int correctCount = 0;
  int mistakes = 0;

  /// Wrong answers the player gave, with the question, for review.
  final missed = <Question>[];

  bool get answered => picked != null;
  bool get hintUsed => removed.isNotEmpty;
  bool get lastCorrect => picked == current.correct;

  void prepareQuestion() {
    options = [current.correct, ...current.wrong]..shuffle(rng);
    removed.clear();
    picked = null;
  }

  /// Records an answer; returns true if it was correct.
  bool answer(String option) {
    if (answered || removed.contains(option)) return false;
    picked = option;
    final ok = option == current.correct;
    if (ok) {
      correctCount++;
    } else {
      mistakes++;
      missed.add(current);
      onWrong();
    }
    notifyListeners();
    return ok;
  }

  void onWrong() {}

  /// 50/50: hides two random wrong options. Returns false if not possible.
  bool useFiftyFifty() {
    if (answered || hintUsed) return false;
    final wrong = options.where((o) => o != current.correct).toList()
      ..shuffle(rng);
    removed.addAll(wrong.take(2));
    notifyListeners();
    return true;
  }
}

/// A stage of 10 fixed questions with 3 lives and 1–3 stars.
class StageSession extends _QuestionFlow {
  final List<Question> questions;
  int index = 0;
  int lives = Rules.lives;
  bool revived = false;

  StageSession(this.questions, {Random? rng}) : super(rng) {
    prepareQuestion();
  }

  @override
  Question get current => questions[index];

  int get total => questions.length;
  bool get failed => lives <= 0;
  bool get isLast => index >= questions.length - 1;
  bool get completed => answered && isLast && !failed;
  bool get canRevive => failed && !revived;
  int get stars => completed ? Rules.starsFor(mistakes) : 0;

  int get coinsEarned => completed
      ? correctCount * Rules.coinsPerCorrect + stars * Rules.coinsPerStar
      : correctCount * Rules.coinsPerCorrect;

  @override
  void onWrong() => lives--;

  /// Moves to the next question. No-op on the last one or after a loss.
  void next() {
    if (!answered || isLast || failed) return;
    index++;
    prepareQuestion();
    notifyListeners();
  }

  /// Second chance after losing all lives (rewarded ad), once per stage.
  void revive() {
    if (!canRevive) return;
    revived = true;
    lives = 1;
    notifyListeners();
  }
}

/// "Time challenge": answer as many as possible in 60 seconds.
/// Time advances through [tick] so the screen drives it from a Ticker and
/// tests can drive it directly.
class TimeChallengeSession extends _QuestionFlow {
  final List<Question> pool;
  int _poolIndex = 0;
  Duration remaining = const Duration(seconds: Rules.challengeSeconds);
  bool revived = false;

  TimeChallengeSession(this.pool, {Random? rng}) : super(rng) {
    assert(pool.isNotEmpty);
    prepareQuestion();
  }

  @override
  Question get current => pool[_poolIndex % pool.length];

  bool get timeUp => remaining <= Duration.zero;
  bool get canRevive => timeUp && !revived;
  int get score => correctCount;
  int get coinsEarned => correctCount * Rules.coinsPerCorrect;

  void tick(Duration dt) {
    if (timeUp) return;
    remaining -= dt;
    if (remaining < Duration.zero) remaining = Duration.zero;
    notifyListeners();
  }

  void next() {
    if (!answered || timeUp) return;
    _poolIndex++;
    prepareQuestion();
    notifyListeners();
  }

  /// Extra seconds after time runs out (rewarded ad), once per run.
  void revive() {
    if (!canRevive) return;
    revived = true;
    remaining = const Duration(seconds: Rules.reviveSeconds);
    if (answered) {
      _poolIndex++;
      prepareQuestion();
    }
    notifyListeners();
  }
}
