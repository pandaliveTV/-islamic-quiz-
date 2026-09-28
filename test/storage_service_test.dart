import 'package:flutter_test/flutter_test.dart';
import 'package:islamicquiz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<StorageService> fresh() async {
    final s = StorageService();
    await s.init();
    return s;
  }

  test('defaults and first launch timestamp', () async {
    final s = await fresh();
    expect(s.coins, 0);
    expect(s.muted, isFalse);
    expect(s.vibration, isTrue);
    expect(s.adsRemoved, isFalse);
    expect(s.firstLaunch, greaterThan(0));
    expect(s.level, 1);
  });

  test('stage progress keeps the best stars and unlocks in order', () async {
    final s = await fresh();
    expect(s.isUnlocked('quran', 0), isTrue);
    expect(s.isUnlocked('quran', 1), isFalse);

    expect(s.saveStage('quran', 0, 2), isTrue);
    expect(s.isUnlocked('quran', 1), isTrue);
    expect(s.saveStage('quran', 0, 1), isFalse);
    expect(s.starsFor('quran', 0), 2);
    expect(s.saveStage('quran', 0, 3), isTrue);
    expect(s.categoryStars('quran'), 3);
    expect(s.completedStages('quran'), 1);
  });

  test('coins, challenge best and settings persist', () async {
    final s = await fresh();
    s.addCoins(30);
    expect(s.spend(50), isFalse);
    expect(s.spend(20), isTrue);
    expect(s.submitChallenge(12), isTrue);
    expect(s.submitChallenge(8), isFalse);
    s.setMuted(true);
    s.setAdsRemoved(true);
    for (var i = 0; i < 4; i++) {
      s.saveStage('fiqh', i, 3);
    }

    final again = await fresh();
    expect(again.coins, 10);
    expect(again.bestChallenge, 12);
    expect(again.muted, isTrue);
    expect(again.adsRemoved, isTrue);
    expect(again.totalStars, 12);
    expect(again.level, 2);
    expect(again.firstLaunch, s.firstLaunch);
  });
}
