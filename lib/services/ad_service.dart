import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_policy.dart';
import 'storage_service.dart';

/// ===================== AdMob unit IDs =====================
/// These are Google's official TEST ids, safe for development.
/// BEFORE PUBLISHING: replace each value with the EliteP unit id from the
/// AdMob console, and replace the App ID in
/// android/app/src/main/AndroidManifest.xml
/// (com.google.android.gms.ads.APPLICATION_ID).
class AdIds {
  static const banner = 'ca-app-pub-3940256099942544/6300978111';
  static const interstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const rewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const appOpen = 'ca-app-pub-3940256099942544/9257395921';
}

/// Single place for all ad logic. Frequency rules live in [AdPolicy].
/// * Banner: Home and Stages screens only.
/// * Interstitial: after every 3 finished rounds, never during questions.
/// * Rewarded: hint / revive / double coins, always player-initiated.
/// * App Open: when returning from background, same 120 s gap.
/// * UMP (GDPR) consent is gathered before any ad is requested.
class AdService extends ChangeNotifier {
  final StorageService storage;
  final AdPolicy policy;

  AdService(this.storage)
    : policy = AdPolicy(firstLaunchMs: storage.firstLaunch) {
    policy.adsRemoved = storage.adsRemoved;
    storage.addListener(_syncAdsRemoved);
  }

  bool _ready = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  AppOpenAd? _appOpen;
  bool _showingFullScreen = false;
  StreamSubscription<AppState>? _appStateSub;

  bool get ready => _ready;
  bool get canShowRewarded =>
      _ready && _rewarded != null && policy.rewardedAllowed;

  /// Set by the quiz screens so no app-open ad interrupts a question.
  set inGameplay(bool v) => policy.inGameplay = v;

  void _syncAdsRemoved() {
    if (policy.adsRemoved == storage.adsRemoved) return;
    policy.adsRemoved = storage.adsRemoved;
    if (storage.adsRemoved) {
      _interstitial?.dispose();
      _interstitial = null;
      _appOpen?.dispose();
      _appOpen = null;
    }
    notifyListeners();
  }

  /// Gathers GDPR consent (UMP) first, then initialises the SDK.
  Future<void> init() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) {
        if (!completer.isCompleted) completer.complete();
      }),
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {},
    );
    if (!await ConsentInformation.instance.canRequestAds()) return;

    await MobileAds.instance.initialize();
    _ready = true;
    _loadInterstitial();
    _loadRewarded();
    _loadAppOpen();
    AppStateEventNotifier.startListening();
    _appStateSub = AppStateEventNotifier.appStateStream.listen((s) {
      if (s == AppState.foreground) _showAppOpen();
    });
    notifyListeners();
  }

  /// Whether the privacy options entry point (UMP) must be shown in settings.
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  void showPrivacyOptions() => ConsentForm.showPrivacyOptionsForm((_) {});

  @override
  void dispose() {
    storage.removeListener(_syncAdsRemoved);
    _appStateSub?.cancel();
    super.dispose();
  }

  // ---------------- Banner ----------------
  BannerAd? createBanner(VoidCallback onLoaded) {
    if (!_ready || !policy.bannerAllowed) return null;
    return BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  // ---------------- Interstitial ----------------
  void _loadInterstitial() {
    if (storage.adsRemoved) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Call when the player leaves a result screen (never mid-question).
  /// Completes once any interstitial shown here has been closed, so the
  /// next round only starts after the ad.
  Future<void> onRoundFinished() {
    if (!policy.onRoundFinished()) return Future.value();
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return Future.value();
    }
    _interstitial = null;
    policy.interstitialShown();
    final done = Completer<void>();
    ad.fullScreenContentCallback = _fullScreenCallback(() {
      _loadInterstitial();
      if (!done.isCompleted) done.complete();
    });
    ad.show();
    return done.future;
  }

  // ---------------- Rewarded ----------------
  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          notifyListeners();
        },
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  /// Shows a rewarded ad (only ever called from a player's tap). Completes
  /// with true only if the reward was earned.
  Future<bool> showRewarded() {
    final ad = _rewarded;
    if (ad == null || !policy.rewardedAllowed) return Future.value(false);
    _rewarded = null;
    notifyListeners();
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = _fullScreenCallback(() {
      _loadRewarded();
      if (!result.isCompleted) result.complete(earned);
    });
    ad.show(onUserEarnedReward: (_, _) => earned = true);
    return result.future;
  }

  // ---------------- App Open ----------------
  void _loadAppOpen() {
    if (storage.adsRemoved) return;
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpen = ad,
        onAdFailedToLoad: (_) => _appOpen = null,
      ),
    );
  }

  void _showAppOpen() {
    final ad = _appOpen;
    if (ad == null || _showingFullScreen || !policy.appOpenAllowed) return;
    _appOpen = null;
    policy.markFullScreen();
    ad.fullScreenContentCallback = _fullScreenCallback(_loadAppOpen);
    ad.show();
  }

  FullScreenContentCallback<T> _fullScreenCallback<T extends Ad>(
    VoidCallback onDone,
  ) {
    return FullScreenContentCallback<T>(
      onAdShowedFullScreenContent: (_) {
        _showingFullScreen = true;
        policy.markFullScreen();
      },
      onAdDismissedFullScreenContent: (ad) {
        _showingFullScreen = false;
        policy.markFullScreen();
        ad.dispose();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _showingFullScreen = false;
        ad.dispose();
        onDone();
      },
    );
  }
}
