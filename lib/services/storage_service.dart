import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists progress (stars per stage, coins, best challenge score) and
/// settings locally with shared_preferences.
class StorageService extends ChangeNotifier {
  late SharedPreferences _p;

  int coins = 0;
  int bestChallenge = 0;
  bool muted = false;
  bool vibration = true;
  bool adsRemoved = false;

  /// Milliseconds since epoch of the very first launch.
  int firstLaunch = 0;

  /// `categoryId` → stars per completed stage (index = stage number).
  final Map<String, List<int>> _stars = {};

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    coins = _p.getInt('coins') ?? 0;
    bestChallenge = _p.getInt('bestChallenge') ?? 0;
    muted = _p.getBool('muted') ?? false;
    vibration = _p.getBool('vibration') ?? true;
    adsRemoved = _p.getBool('adsRemoved') ?? false;
    firstLaunch = _p.getInt('firstLaunch') ?? 0;
    if (firstLaunch == 0) {
      firstLaunch = DateTime.now().millisecondsSinceEpoch;
      await _p.setInt('firstLaunch', firstLaunch);
    }
    final raw = _p.getString('stars');
    if (raw != null) {
      try {
        (jsonDecode(raw) as Map<String, dynamic>).forEach(
          (k, v) => _stars[k] = (v as List).cast<int>().toList(),
        );
      } catch (_) {
        // Corrupt data: start fresh rather than crash.
      }
    }
  }

  // ---------------- Progress ----------------

  int starsFor(String categoryId, int stage) {
    final list = _stars[categoryId];
    return list != null && stage < list.length ? list[stage] : 0;
  }

  /// Stages are unlocked in order: the next one opens after passing the
  /// previous stage (at least one star).
  bool isUnlocked(String categoryId, int stage) =>
      stage == 0 || starsFor(categoryId, stage - 1) > 0;

  int completedStages(String categoryId) =>
      _stars[categoryId]?.where((s) => s > 0).length ?? 0;

  int categoryStars(String categoryId) =>
      _stars[categoryId]?.fold<int>(0, (a, b) => a + b) ?? 0;

  int get totalStars => _stars.keys.fold(0, (a, k) => a + categoryStars(k));

  /// Player level grows with every 10 stars earned.
  int get level => totalStars ~/ 10 + 1;

  /// Keeps the best result for the stage. Returns true if it improved.
  bool saveStage(String categoryId, int stage, int stars) {
    final list = _stars.putIfAbsent(categoryId, () => []);
    while (list.length <= stage) {
      list.add(0);
    }
    if (stars <= list[stage]) return false;
    list[stage] = stars;
    _p.setString('stars', jsonEncode(_stars));
    notifyListeners();
    return true;
  }

  // ---------------- Coins & score ----------------

  void addCoins(int n) {
    coins += n;
    _p.setInt('coins', coins);
    notifyListeners();
  }

  bool spend(int n) {
    if (coins < n) return false;
    addCoins(-n);
    return true;
  }

  /// Returns true when [score] is a new time-challenge record.
  bool submitChallenge(int score) {
    if (score <= bestChallenge) return false;
    bestChallenge = score;
    _p.setInt('bestChallenge', score);
    notifyListeners();
    return true;
  }

  // ---------------- Settings ----------------

  void setMuted(bool v) {
    muted = v;
    _p.setBool('muted', v);
    notifyListeners();
  }

  void setVibration(bool v) {
    vibration = v;
    _p.setBool('vibration', v);
    notifyListeners();
  }

  void setAdsRemoved(bool v) {
    adsRemoved = v;
    _p.setBool('adsRemoved', v);
    notifyListeners();
  }
}
