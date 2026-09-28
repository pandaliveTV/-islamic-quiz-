import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

/// Loads the question bank from bundled JSON assets and splits every
/// category into fixed stages of [stageSize] questions.
class QuestionRepository {
  static const stageSize = 10;

  final AssetBundle bundle;
  final _cache = <String, List<Question>>{};

  QuestionRepository({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  static List<Question> parse(String json) => (jsonDecode(json) as List)
      .map((e) => Question.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);

  Future<List<Question>> load(String categoryId) async {
    final cached = _cache[categoryId];
    if (cached != null) return cached;
    final raw = await bundle.loadString(categoryById(categoryId).asset);
    return _cache[categoryId] = parse(raw);
  }

  Future<void> preloadAll() async {
    for (final c in categories) {
      await load(c.id);
    }
  }

  /// Number of complete stages available in a category (0 if not loaded yet).
  int stageCount(String categoryId) =>
      (_cache[categoryId]?.length ?? 0) ~/ stageSize;

  /// Questions of stage [stage] (0-based), always in the same order so stars
  /// earned for a stage stay meaningful.
  Future<List<Question>> stage(String categoryId, int stage) async {
    final all = await load(categoryId);
    final start = stage * stageSize;
    return all.sublist(start, start + stageSize);
  }

  /// A shuffled mix of every category, used by the time challenge.
  Future<List<Question>> mixed() async {
    await preloadAll();
    return [for (final q in _cache.values) ...q]..shuffle();
  }
}
