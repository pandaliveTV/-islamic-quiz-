import 'package:url_launcher/url_launcher.dart';

/// External links used by the app.
class Links {
  /// TODO(EliteP): replace with the published privacy policy URL.
  static const privacyPolicy = 'https://elitep.com/privacy';

  static const prayerTimesPackage = 'com.elitep.prayertimes';

  static Future<bool> openPrivacyPolicy() =>
      launchUrl(Uri.parse(privacyPolicy), mode: LaunchMode.externalApplication);

  /// Opens EliteP's prayer-times app page in Google Play (market:// first,
  /// then the web page as a fallback).
  static Future<bool> openPrayerTimes() async {
    try {
      if (await launchUrl(
        Uri.parse('market://details?id=$prayerTimesPackage'),
        mode: LaunchMode.externalApplication,
      )) {
        return true;
      }
    } catch (_) {
      // Play Store app missing; fall through to the web page.
    }
    return launchUrl(
      Uri.parse(
        'https://play.google.com/store/apps/details?id=$prayerTimesPackage',
      ),
      mode: LaunchMode.externalApplication,
    );
  }
}
