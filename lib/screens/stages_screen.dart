import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/question_repository.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';
import '../widgets/ornaments.dart';
import '../widgets/theme.dart';
import 'quiz_screen.dart';

class StagesScreen extends StatelessWidget {
  final QuizCategory category;
  const StagesScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StorageService>();
    final count = context.read<QuestionRepository>().stageCount(category.id);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(category.title),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12),
            child: CoinBadge(),
          ),
        ],
      ),
      body: IslamicBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      '${s.categoryStars(category.id)} / ${count * 3}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 110,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: count,
                  itemBuilder: (_, i) => _StageTile(
                    category: category,
                    stage: i,
                    unlocked: s.isUnlocked(category.id, i),
                    stars: s.starsFor(category.id, i),
                  ),
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

class _StageTile extends StatelessWidget {
  final QuizCategory category;
  final int stage;
  final bool unlocked;
  final int stars;
  const _StageTile({
    required this.category,
    required this.stage,
    required this.unlocked,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: unlocked
          ? category.color.withValues(alpha: 0.45)
          : Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: stars > 0
              ? AppColors.gold
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: unlocked
            ? () {
                context.read<AudioService>().tap();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        QuizScreen(category: category, stage: stage),
                  ),
                );
              }
            : () => showSnack(context, 'أكمل المرحلة السابقة أولاً'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            unlocked
                ? Text(
                    '${stage + 1}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : const Icon(Icons.lock, color: Colors.white38),
            const SizedBox(height: 6),
            StarsRow(stars, size: 15),
          ],
        ),
      ),
    );
  }
}
