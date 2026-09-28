/// Pure frequency rules for ads, kept free of the ads SDK so it can be
/// unit-tested:
/// * no ad of any kind in the first 60 s after the very first launch
/// * at least 120 s between any two full-screen ads
/// * an interstitial after every 3 finished rounds
/// * "Remove Ads" disables banner / interstitial / app open (not rewarded)
/// * nothing but player-requested rewarded ads while a question is on screen
class AdPolicy {
  static const minGap = Duration(seconds: 120);
  static const firstRunGrace = Duration(seconds: 60);
  static const roundsPerInterstitial = 3;

  final int firstLaunchMs;
  final DateTime Function() now;

  AdPolicy({required this.firstLaunchMs, DateTime Function()? clock})
    : now = clock ?? DateTime.now;

  DateTime? lastFullScreen;
  int rounds = 0;
  bool adsRemoved = false;

  /// True while a quiz question is on screen.
  bool inGameplay = false;

  bool get inGrace =>
      now().millisecondsSinceEpoch - firstLaunchMs <
      firstRunGrace.inMilliseconds;

  Duration get graceRemaining {
    final left =
        firstRunGrace.inMilliseconds -
        (now().millisecondsSinceEpoch - firstLaunchMs);
    return left > 0 ? Duration(milliseconds: left) : Duration.zero;
  }

  bool get gapOk =>
      lastFullScreen == null || now().difference(lastFullScreen!) >= minGap;

  bool get bannerAllowed => !adsRemoved && !inGrace;

  bool get _fullScreenAllowed =>
      !adsRemoved && !inGrace && !inGameplay && gapOk;

  /// Call once per finished round. Returns true when an interstitial is due.
  /// The round counter keeps running so the ad follows the next eligible
  /// multiple of 3 if it is blocked now.
  bool onRoundFinished() {
    rounds++;
    return rounds >= roundsPerInterstitial && _fullScreenAllowed;
  }

  /// Resets the round counter once an interstitial was actually shown.
  void interstitialShown() {
    rounds = 0;
    markFullScreen();
  }

  bool get appOpenAllowed => _fullScreenAllowed;

  /// Rewarded ads are always player-initiated, so only the first-run grace
  /// applies (they remain available after "Remove Ads").
  bool get rewardedAllowed => !inGrace;

  void markFullScreen() => lastFullScreen = now();
}
