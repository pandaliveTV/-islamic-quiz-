import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/question_repository.dart';
import '../services/audio_service.dart';
import '../services/links.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';
import '../widgets/ornaments.dart';
import '../widgets/theme.dart';
import 'challenge_screen.dart';
import 'settings_screen.dart';
import 'stages_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StorageService>();
    return Scaffold(
      body: IslamicBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    const CoinBadge(),
                    const SizedBox(width: 8),
                    Pill(icon: Icons.military_tech, text: 'المستوى ${s.level}'),
                    const Spacer(),
                    IconButton(
                      tooltip: 'الإعدادات',
                      icon: const Icon(Icons.settings),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: _Header()),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: _ChallengeCard(best: s.bestChallenge),
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'الفئات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldSoft,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.05,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _CategoryCard(categories[i]),
                          childCount: categories.length,
                        ),
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(child: _PrayerTimesCard()),
                    ),
                  ],
                ),
              ),
              const BannerSlot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          StarMedallion(
            size: 84,
            child: Icon(Icons.menu_book, color: AppColors.gold, size: 30),
          ),
          SizedBox(height: 10),
          Text(
            'مسابقة إسلامية',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          OrnamentDivider(),
          SizedBox(height: 6),
          Text(
            'اختبر معلوماتك وتعلّم في كل سؤال',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final int best;
  const _ChallengeCard({required this.best});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gold.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.gold, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          context.read<AudioService>().tap();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChallengeScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.timer, size: 40, color: AppColors.gold),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تحدي الوقت',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'أجب عن أكبر عدد من الأسئلة في 60 ثانية',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'أعلى نتيجة: $best',
                      style: const TextStyle(
                        color: AppColors.goldSoft,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final QuizCategory category;
  const _CategoryCard(this.category);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StorageService>();
    final total = context.read<QuestionRepository>().stageCount(category.id);
    final done = s.completedStages(category.id);
    return Material(
      color: category.color.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: category.color.withValues(alpha: 0.9)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          context.read<AudioService>().tap();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StagesScreen(category: category)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(category.icon, size: 38, color: AppColors.goldSoft),
              const SizedBox(height: 8),
              FittedBox(
                child: Text(
                  category.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 6,
                  backgroundColor: Colors.black26,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$done / $total مرحلة',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional cross-promotion for EliteP's prayer-times app.
class _PrayerTimesCard extends StatelessWidget {
  const _PrayerTimesCard();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      tileColor: Colors.black12,
      leading: const Icon(Icons.access_time, color: AppColors.gold),
      title: const Text('مواقيت الصلاة'),
      subtitle: const Text(
        'تطبيق مواقيت الصلاة من EliteP',
        style: TextStyle(color: Colors.white60),
      ),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: Links.openPrayerTimes,
    );
  }
}
