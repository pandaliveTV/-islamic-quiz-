import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ad_service.dart';
import '../services/iap_service.dart';
import '../services/links.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';
import '../widgets/ornaments.dart';
import '../widgets/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StorageService>();
    final iap = context.read<IapService>();
    final ads = context.read<AdService>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('الإعدادات')),
      body: IslamicBackground(
        child: SafeArea(
          child: ListView(
            children: [
              SwitchListTile(
                title: const Text('المؤثرات الصوتية'),
                secondary: Icon(s.muted ? Icons.volume_off : Icons.volume_up),
                value: !s.muted,
                activeThumbColor: AppColors.gold,
                onChanged: (v) => s.setMuted(!v),
              ),
              SwitchListTile(
                title: const Text('الاهتزاز'),
                secondary: const Icon(Icons.vibration),
                value: s.vibration,
                activeThumbColor: AppColors.gold,
                onChanged: s.setVibration,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(
                  s.adsRemoved
                      ? 'تمت إزالة الإعلانات — جزاك الله خيراً'
                      : 'إزالة الإعلانات',
                ),
                subtitle: s.adsRemoved
                    ? null
                    : Text(
                        iap.product?.price ?? 'يزيل إعلانات البانر والإعلانات البينية وإعلانات الفتح',
                      ),
                onTap: s.adsRemoved
                    ? null
                    : () async {
                        final ok = await iap.buyRemoveAds();
                        if (!ok && context.mounted) {
                          showSnack(context, 'المتجر غير متاح حالياً');
                        }
                      },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('استعادة المشتريات'),
                onTap: iap.restore,
              ),
              FutureBuilder<bool>(
                future: ads.privacyOptionsRequired().catchError((_) => false),
                builder: (_, snap) => snap.data == true
                    ? ListTile(
                        leading: const Icon(Icons.shield_outlined),
                        title: const Text('خيارات الخصوصية للإعلانات'),
                        onTap: ads.showPrivacyOptions,
                      )
                    : const SizedBox.shrink(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('تطبيق مواقيت الصلاة من EliteP'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: Links.openPrayerTimes,
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('سياسة الخصوصية'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: Links.openPrivacyPolicy,
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('مسابقة إسلامية — EliteP'),
                subtitle: Text('الإصدار 1.0.0'),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'الأسئلة مراجعة من مصادر موثوقة، وإن وجدت خطأً فراسلنا لنصححه.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
