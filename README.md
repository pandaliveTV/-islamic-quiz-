# مسابقة إسلامية — Islamic Quiz (EliteP)

Arabic (RTL) Islamic quiz game for Android, built with Flutter.
Package: `com.elitep.islamicquiz` · Portrait only · No music, soft sound effects only.

## Features
- **6 categories**: القرآن الكريم، السيرة النبوية، الصحابة، الفقه، الأنبياء، التاريخ الإسلامي.
- **1060 questions** (170–200 per category), each with a short source/explanation shown after answering.
- **Stages** of 10 questions, 3 lives, **1–3 stars** by mistakes (0 → 3★, 1 → 2★, 2+ → 1★). Stages unlock in order.
- **Time challenge**: as many correct answers as possible in 60 s, questions mixed from all categories; best score saved.
- **50/50 hint** (remove two wrong answers) for 20 coins or a rewarded ad (coins only in the time challenge).
- **Revive** after losing (rewarded ad, once per round) and **double coins** on the result screen (rewarded ad).
- Review of missed questions with explanations at the end of each round.
- Progress saved locally (stars per stage, level, coins, best score, settings) with `shared_preferences`.
- Sound toggle, vibration toggle (HapticFeedback), privacy policy link, optional link to EliteP Prayer Times.

## Run
```bash
flutter pub get
flutter run            # device/emulator with Google Play services
flutter analyze        # must be clean
flutter test           # logic, ad rules, storage, question-bank validation, UI smoke test
```

## Project layout
```
lib/
  main.dart              providers, portrait lock, Arabic locale (RTL)
  data/                  models (Question, categories), QuestionRepository (JSON → stages)
  game/quiz_session.dart StageSession, TimeChallengeSession, Rules (stars, coins, hint cost)
  screens/               splash, home, stages, quiz, challenge, result, settings
  services/              ad_service, ad_policy, iap_service, storage_service, audio_service, links
  widgets/               theme, Islamic ornaments, question view, dialogs, banner slot
assets/questions/        one JSON file per category
assets/sounds/           short synthesized effects (tap, correct, wrong, win, coin)
store/                   512×512 Play Store icon
```

## Editing questions
Each file in `assets/questions/` is a JSON array of:
```json
{"q": "question", "c": "correct answer", "w": ["wrong 1", "wrong 2", "wrong 3"], "e": "short source / explanation"}
```
Options are shuffled at runtime. Stages are consecutive blocks of 10 in file order, so keep each
file a multiple of 10 and **append** new questions at the end (inserting would shift existing stages).
`flutter test` validates the bank (≥1000 total, 4 distinct options, no duplicates, explanation present).

## AdMob — where to change IDs
Development uses **Google's official test IDs**. Before release replace:
1. `lib/services/ad_service.dart` → class **`AdIds`** (banner, interstitial, rewarded, appOpen).
2. `android/app/src/main/AndroidManifest.xml` → meta-data **`com.google.android.gms.ads.APPLICATION_ID`**.
3. In AdMob → *Privacy & messaging*, publish a **GDPR (UMP) message** for the app. Consent is requested
   before any ad loads; a "خيارات الخصوصية للإعلانات" entry appears in Settings when required.

Ad rules (all in `AdService` / `AdPolicy`, unit-tested in `test/ad_policy_test.dart`):
| Format | Where / when |
|---|---|
| Banner | Home and Stages screens only (never during play) |
| Interstitial | when leaving the result screen, every 3 finished rounds, ≥120 s since any full-screen ad; the next round starts only after it closes |
| Rewarded | only on the player's tap: hint, revive, double coins |
| App Open | returning from background, same 120 s gap, never while a question is on screen |
| All | none in the first 60 s after the very first launch |

"Remove Ads" disables banner, interstitial and app open; rewarded stays available (opt-in).

## In-app purchase
Create a **managed (non-consumable) product** with id `remove_ads` in Play Console
(`lib/services/iap_service.dart`). Settings has *Remove Ads* and *Restore purchases*.

## Links
- Privacy policy URL: `lib/services/links.dart` → `Links.privacyPolicy` (**replace before publishing**).
- Prayer Times app: `com.elitep.prayertimes` (opens Google Play).

## Build the AAB for Google Play
1. Create an upload keystore (once, keep it safe):
   ```bash
   keytool -genkey -v -keystore ~/elitep-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (git-ignored):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolute/path/to/elitep-upload.jks
   ```
   `android/app/build.gradle.kts` already signs release builds with it when the file exists
   (falls back to the debug key otherwise).
3. Bump `version:` in `pubspec.yaml` (e.g. `1.0.1+2`) for every upload.
4. Build:
   ```bash
   flutter build appbundle --release
   ```
5. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.
   Declare ads = yes, fill the Data safety form (AdMob advertising ID, purchases), and use
   `store/play_icon_512.png` plus `store_listing.md` for the listing.
