import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/question_repository.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';
import '../widgets/ornaments.dart';
import '../widgets/theme.dart';
import 'challenge_screen.dart';
import 'quiz_screen.dart';

/// End of a round (stage or time challenge): saves progress, grants coins,
/// offers "double coins" via a rewarded ad and lets the player review
/// missed questions. Interstitials may only appear when leaving this screen.
class ResultScreen extends StatefulWidget {
  final QuizCategory? category;
  final int stage;
  final int stars;
  final int correct;
  final int total;
  final int coins;
  final List<Question> missed;

  const ResultScreen.stage({
    super.key,
    required QuizCategory this.category,
    required this.stage,
    required this.stars,
    required this.correct,
    required this.total,
    required this.coins,
    required this.missed,
  });

  const ResultScreen.challenge({
    super.key,
    required int score,
    required this.coins,
    required this.missed,
  }) : category = null,
       stage = 0,
       stars = 0,
       correct = score,
       total = 0;

  bool get isChallenge => category == null;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final StorageService _storage = context.read<StorageService>();
  bool _record = false;
  bool _doubled = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    // Progress is saved after the first frame: notifying listeners while
    // this route is being built would trigger a rebuild during build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _grant());
  }

  void _grant() {
    if (!mounted) return;
    final w = widget;
    _storage.addCoins(w.coins);
    if (w.isChallenge) {
      setState(() => _record = _storage.submitChallenge(w.correct));
    } else if (w.stars > 0) {
      _storage.saveStage(w.category!.id, w.stage, w.stars);
    }
    if (w.isChallenge || w.stars > 0) context.read<AudioService>().win();
  }

  Future<void> _double() async {
    final earned = await context.read<AdService>().showRewarded();
    if (!mounted) return;
    if (earned) {
      _storage.addCoins(widget.coins);
      context.read<AudioService>().coin();
      setState(() => _doubled = true);
    } else {
      showSnack(context, 'لم يكتمل الإعلان');
    }
  }

  /// Leaves the result screen; an interstitial (if due) is shown first.
  Future<void> _leave(Widget? next) async {
    if (_leaving) return;
    _leaving = true;
    context.read<AudioService>().tap();
    await context.read<AdService>().onRoundFinished();
    if (!mounted) return;
    if (next == null) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => next),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final passed = w.isChallenge || w.stars > 0;
    final ads = context.watch<AdService>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(null);
      },
      child: Scaffold(
        body: IslamicBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 12),
                Center(
                  child: StarMedallion(
                    size: 110,
                    child: Icon(
                      w.isChallenge
                          ? Icons.timer
                          : passed
                          ? Icons.emoji_events
                          : Icons.refresh,
                      size: 38,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _title(passed),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (!w.isChallenge) Center(child: StarsRow(w.stars, size: 44)),
                const SizedBox(height: 8),
                Text(
                  w.isChallenge
                      ? 'إجابات صحيحة: ${w.correct}   •   أعلى نتيجة: ${_storage.bestChallenge}'
                      : 'إجابات صحيحة: ${w.correct} من ${w.total}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Pill(
                    icon: Icons.monetization_on,
                    iconColor: AppColors.gold,
                    text: '+${_doubled ? w.coins * 2 : w.coins}',
                  ),
                ),
                const SizedBox(height: 20),
                if (w.coins > 0 && !_doubled && ads.canShowRewarded) ...[
                  ActionButton(
                    'ضاعف العملات بمشاهدة إعلان',
                    icon: Icons.ondemand_video,
                    primary: false,
                    onPressed: _double,
                  ),
                  const SizedBox(height: 10),
                ],
                ..._actions(passed),
                if (w.missed.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const OrnamentDivider(width: double.infinity),
                  _Review(w.missed),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(bool passed) {
    if (widget.isChallenge) return _record ? 'رقم قياسي جديد!' : 'انتهى التحدي';
    if (!passed) return 'حاول مرة أخرى';
    return switch (widget.stars) {
      3 => 'ممتاز! بارك الله فيك',
      2 => 'أحسنت!',
      _ => 'اجتزت المرحلة',
    };
  }

  List<Widget> _actions(bool passed) {
    final w = widget;
    if (w.isChallenge) {
      return [
        ActionButton(
          'العب مجدداً',
          icon: Icons.replay,
          onPressed: () => _leave(const ChallengeScreen()),
        ),
        const SizedBox(height: 10),
        ActionButton(
          'الرئيسية',
          icon: Icons.home,
          primary: false,
          onPressed: () => _leave(null),
        ),
      ];
    }
    final cat = w.category!;
    final stageCount = context.read<QuestionRepository>().stageCount(cat.id);
    final hasNext = passed && w.stage + 1 < stageCount;
    return [
      if (hasNext) ...[
        ActionButton(
          'المرحلة التالية',
          icon: Icons.arrow_forward,
          onPressed: () =>
              _leave(QuizScreen(category: cat, stage: w.stage + 1)),
        ),
        const SizedBox(height: 10),
      ],
      ActionButton(
        'إعادة المرحلة',
        icon: Icons.replay,
        primary: !hasNext,
        onPressed: () => _leave(QuizScreen(category: cat, stage: w.stage)),
      ),
      const SizedBox(height: 10),
      ActionButton(
        'المراحل',
        icon: Icons.grid_view,
        primary: false,
        onPressed: () => _leave(null),
      ),
    ];
  }
}

/// Missed questions with the right answer and explanation.
class _Review extends StatelessWidget {
  final List<Question> missed;
  const _Review(this.missed);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      iconColor: AppColors.gold,
      collapsedIconColor: AppColors.gold,
      title: Text(
        'مراجعة الأخطاء (${missed.length})',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        for (final q in missed)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.text,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '✔ ${q.correct}',
                  style: const TextStyle(color: AppColors.correct),
                ),
                const SizedBox(height: 4),
                Text(
                  q.explanation,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
