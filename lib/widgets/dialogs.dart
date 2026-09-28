import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/quiz_session.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';
import 'common.dart';
import 'theme.dart';

/// Lets the player choose how to pay for the 50/50 hint: coins or a
/// rewarded ad. Returns true when the hint was paid for.
Future<bool> payForHint(BuildContext context, {bool allowAd = true}) async {
  final storage = context.read<StorageService>();
  final ads = context.read<AdService>();
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.green,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'حذف إجابتين',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'يحذف إجابتين خاطئتين من هذا السؤال',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ActionButton(
              'استخدم ${Rules.hintCost} عملة (لديك ${storage.coins})',
              icon: Icons.monetization_on,
              onPressed: storage.coins >= Rules.hintCost
                  ? () => Navigator.pop(ctx, 'coins')
                  : null,
            ),
            if (allowAd) ...[
              const SizedBox(height: 10),
              ActionButton(
                ads.canShowRewarded
                    ? 'شاهد إعلاناً مجاناً'
                    : 'الإعلان غير متاح الآن',
                icon: Icons.ondemand_video,
                primary: false,
                onPressed: ads.canShowRewarded
                    ? () => Navigator.pop(ctx, 'ad')
                    : null,
              ),
            ],
          ],
        ),
      ),
    ),
  );
  if (choice == 'coins') return storage.spend(Rules.hintCost);
  if (choice == 'ad') return ads.showRewarded();
  return false;
}

/// Confirms leaving a round in progress.
Future<bool> confirmExit(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.green,
      title: const Text('الخروج من الجولة؟'),
      content: const Text('سيضيع تقدمك في هذه الجولة.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('متابعة اللعب'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('خروج'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Offered after losing: revive with a rewarded ad (player's choice).
/// Returns true if the player watched the ad and earned the reward.
Future<bool> offerRevive(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ads = context.read<AdService>();
  final choice = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.green,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إنهاء'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.ondemand_video),
          label: const Text('فرصة ثانية بإعلان'),
        ),
      ],
    ),
  );
  if (choice != true) return false;
  final earned = await ads.showRewarded();
  if (!earned && context.mounted) {
    showSnack(context, 'لم يكتمل الإعلان');
  }
  return earned;
}
