import 'package:flutter_test/flutter_test.dart';
import 'package:islamicquiz/services/ad_policy.dart';

void main() {
  late DateTime now;
  late AdPolicy p;
  final start = DateTime(2026, 1, 1, 12);

  setUp(() {
    now = start;
    p = AdPolicy(firstLaunchMs: start.millisecondsSinceEpoch, clock: () => now);
  });

  void advance(Duration d) => now = now.add(d);

  test('no ads at all during the first 60 seconds', () {
    expect(p.inGrace, isTrue);
    expect(p.bannerAllowed, isFalse);
    expect(p.appOpenAllowed, isFalse);
    expect(p.rewardedAllowed, isFalse);
    advance(const Duration(seconds: 61));
    expect(p.bannerAllowed, isTrue);
    expect(p.appOpenAllowed, isTrue);
    expect(p.rewardedAllowed, isTrue);
  });

  test('interstitial after every 3 rounds', () {
    advance(const Duration(minutes: 5));
    expect(p.onRoundFinished(), isFalse);
    expect(p.onRoundFinished(), isFalse);
    expect(p.onRoundFinished(), isTrue);
    p.interstitialShown();
    advance(const Duration(minutes: 5));
    expect(p.onRoundFinished(), isFalse);
    expect(p.onRoundFinished(), isFalse);
    expect(p.onRoundFinished(), isTrue);
  });

  test('at least 120 seconds between full-screen ads', () {
    advance(const Duration(minutes: 5));
    p.markFullScreen(); // e.g. an app-open ad
    p.onRoundFinished();
    p.onRoundFinished();
    advance(const Duration(seconds: 60));
    expect(p.onRoundFinished(), isFalse, reason: 'gap not reached');
    advance(const Duration(seconds: 60));
    expect(p.onRoundFinished(), isTrue, reason: 'due round carries over');
    expect(p.appOpenAllowed, isTrue);
    p.interstitialShown();
    expect(p.appOpenAllowed, isFalse);
  });

  test('never during gameplay', () {
    advance(const Duration(minutes: 5));
    p.inGameplay = true;
    expect(p.appOpenAllowed, isFalse);
    p.inGameplay = false;
    expect(p.appOpenAllowed, isTrue);
  });

  test(
    'remove ads disables banner, interstitial and app open, not rewarded',
    () {
      advance(const Duration(minutes: 5));
      p.adsRemoved = true;
      expect(p.bannerAllowed, isFalse);
      expect(p.appOpenAllowed, isFalse);
      for (var i = 0; i < 6; i++) {
        expect(p.onRoundFinished(), isFalse);
      }
      expect(p.rewardedAllowed, isTrue);
    },
  );
}
