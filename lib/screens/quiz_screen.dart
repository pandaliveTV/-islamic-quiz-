import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/question_repository.dart';
import '../game/quiz_session.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import '../widgets/ornaments.dart';
import '../widgets/question_view.dart';
import '../widgets/theme.dart';
import 'result_screen.dart';

/// Plays one stage (10 questions, 3 lives). No ads are shown here except a
/// rewarded ad the player explicitly asks for.
class QuizScreen extends StatefulWidget {
  final QuizCategory category;
  final int stage;
  const QuizScreen({super.key, required this.category, required this.stage});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  StageSession? _session;
  late final AdService _ads = context.read<AdService>();
  late final AudioService _audio = context.read<AudioService>();

  @override
  void initState() {
    super.initState();
    _ads.inGameplay = true;
    context
        .read<QuestionRepository>()
        .stage(widget.category.id, widget.stage)
        .then((qs) {
          if (mounted) setState(() => _session = StageSession(qs));
        });
  }

  @override
  void dispose() {
    _ads.inGameplay = false;
    _session?.dispose();
    super.dispose();
  }

  void _pick(String option) {
    final s = _session!;
    final ok = s.answer(option);
    ok ? _audio.correct() : _audio.wrong();
    if (s.failed) _onLost();
  }

  Future<void> _onLost() async {
    final s = _session!;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (s.canRevive && _ads.canShowRewarded) {
      final revived = await offerRevive(
        context,
        title: 'نفدت المحاولات',
        message: 'شاهد إعلاناً لتحصل على محاولة إضافية وتكمل المرحلة.',
      );
      if (!mounted) return;
      if (revived) {
        s.revive();
        return;
      }
    }
    _finish();
  }

  Future<void> _hint() async {
    final s = _session!;
    if (s.answered || s.hintUsed) return;
    _audio.tap();
    if (await payForHint(context)) {
      s.useFiftyFifty();
      _audio.coin();
    }
  }

  void _next() {
    final s = _session!;
    _audio.tap();
    if (s.isLast || s.failed) {
      _finish();
    } else {
      s.next();
    }
  }

  void _finish() {
    final s = _session!;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen.stage(
          category: widget.category,
          stage: widget.stage,
          stars: s.stars,
          correct: s.correctCount,
          total: s.total,
          coins: s.coinsEarned,
          missed: s.missed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await confirmExit(context) && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: IslamicBackground(
          child: SafeArea(
            child: s == null
                ? const Center(child: CircularProgressIndicator())
                : ListenableBuilder(
                    listenable: s,
                    builder: (context, _) => _body(s),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _body(StageSession s) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.maybePop(context),
              ),
              Text(
                '${widget.category.title} • ${widget.stage + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              for (var i = 0; i < Rules.lives; i++)
                Icon(
                  i < s.lives ? Icons.favorite : Icons.favorite_border,
                  color: AppColors.wrong,
                  size: 22,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('${s.index + 1} / ${s.total}'),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (s.index + (s.answered ? 1 : 0)) / s.total,
                    minHeight: 6,
                    backgroundColor: Colors.black26,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QuestionView(
                  key: ValueKey(s.index),
                  question: s.current,
                  options: s.options,
                  removed: s.removed,
                  picked: s.picked,
                  onPick: _pick,
                ),
                if (s.answered) ...[
                  const SizedBox(height: 6),
                  ExplanationCard(correct: s.lastCorrect, question: s.current),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: s.answered
              ? ActionButton(
                  s.isLast || s.failed ? 'النتيجة' : 'التالي',
                  icon: Icons.arrow_forward,
                  onPressed: s.failed ? null : _next,
                )
              : Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        'حذف إجابتين',
                        icon: Icons.lightbulb,
                        primary: false,
                        onPressed: s.hintUsed ? null : _hint,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const CoinBadge(),
                  ],
                ),
        ),
      ],
    );
  }
}
