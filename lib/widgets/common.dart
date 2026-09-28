import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/ad_service.dart';
import '../services/storage_service.dart';
import 'theme.dart';

class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final coins = context.select<StorageService, int>((s) => s.coins);
    return Pill(
      icon: Icons.monetization_on,
      iconColor: AppColors.gold,
      text: '$coins',
    );
  }
}

class Pill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  const Pill({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor = AppColors.goldSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class StarsRow extends StatelessWidget {
  final int stars;
  final double size;
  const StarsRow(this.stars, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? AppColors.gold : Colors.white30,
          ),
      ],
    );
  }
}

/// Full-width rounded action button.
class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  const ActionButton(
    this.label, {
    super.key,
    required this.icon,
    this.onPressed,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      backgroundColor: primary ? AppColors.gold : Colors.white12,
      foregroundColor: primary ? AppColors.deep : AppColors.cream,
      disabledBackgroundColor: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );
    return FilledButton.icon(
      style: style,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Banner shown only on the Home and Stages screens (never during play).
class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key});

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  Timer? _retry;
  late final AdService _ads = context.read<AdService>();

  @override
  void initState() {
    super.initState();
    _ads.addListener(_tryLoad);
    _tryLoad();
  }

  /// The SDK initialises after consent, possibly after this screen opened.
  void _tryLoad() {
    if (_ad != null) return;
    _ad = _ads.createBanner(() {
      if (mounted) setState(() => _loaded = true);
    });
    // Still inside the first-run grace period: try again once it ends.
    final wait = _ads.policy.graceRemaining;
    if (_ad == null && _ads.ready && wait > Duration.zero) {
      _retry?.cancel();
      _retry = Timer(wait + const Duration(seconds: 1), _tryLoad);
    }
  }

  @override
  void dispose() {
    _ads.removeListener(_tryLoad);
    _retry?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final removed = context.select<StorageService, bool>((s) => s.adsRemoved);
    final ad = _ad;
    if (removed || !_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
