import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

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

/// "Time challenge": as many correct answers as possible in 60 seconds,
/// questions mixed from every category.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  TimeChallengeSession? _session;
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastElapsed = Duration.zero;
  static const _maxFrameGap = Duration(milliseconds: 100);
  bool _ending = false;
  late final AdService _ads = context.read<AdService>();
  late final AudioService _audio = context.read<AudioService>();

  @override
  void initState() {
    super.initState();
    _ads.inGameplay = true;
    context.read<QuestionRepository>().mixed().then((qs) {
      if (!mounted) return;
      setState(() => _session = TimeChallengeSession(qs));
      _resume();
    });
  }

  @override
  void dispose() {
    _ads.inGameplay = false;
    _ticker.dispose();
    _session?.dispose();
    super.dispose();
  }

  void _resume() {
    _lastElapsed = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _pause() {
    if (_ticker.isActive) _ticker.stop();
  }

  void _onTick(Duration elapsed) {
    final s = _session!;
    var dt = elapsed - _lastElapsed;
    _lastElapsed = elapsed;
    // Frames stop while the app is in the background; don't count that gap.
    if (dt > _maxFrameGap) dt = _maxFrameGap;
    s.tick(dt);
    if (s.timeUp) {
      _pause();
      _onTimeUp();
    }
  }

  Future<void> _onTimeUp() async {
    if (_ending) return;
    _ending = true;
    final s = _session!;
    _audio.wrong();
    if (s.canRevive && _ads.canShowRewarded) {
      final revived = await offerRevive(
        context,
        title: 'انتهى الوقت!',
        message:
            'نتيجتك ${s.score}. شاهد إعلاناً لتحصل على ${Rules.reviveSeconds} ثانية إضافية.',
      );
      if (!mounted) return;
      if (revived) {
        s.revive();
        _ending = false;
        _resume();
        return;
      }
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen.challenge(
          score: s.score,
          coins: s.coinsEarned,
          missed: s.missed,
        ),
      ),
    );
  }

  void _pick(String option) {
    final s = _session!;
    s.answer(option) ? _audio.correct() : _audio.wrong();
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) s.next();
    });
  }

  Future<void> _hint() async {
    final s = _session!;
    if (s.answered || s.hintUsed) return;
    _pause();
    // Coins only here: a rewarded ad mid-countdown would break the timer.
    final paid = await payForHint(context, allowAd: false);
    if (!mounted) return;
    if (paid) {
      s.useFiftyFifty();
      _audio.coin();
    }
    _resume();
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _ending) return;
        _pause();
        final exit = await confirmExit(context);
        if (!context.mounted) return;
        exit ? Navigator.pop(context) : _resume();
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

  Widget _body(TimeChallengeSession s) {
    final secs = (s.remaining.inMilliseconds / 1000).ceil();
    final fraction =
        s.remaining.inMilliseconds / (Rules.challengeSeconds * 1000);
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
              const Text(
                'تحدي الوقت',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Pill(icon: Icons.check, text: '${s.score}'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.timer,
                color: secs <= 10 ? AppColors.wrong : AppColors.gold,
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 28,
                child: Text(
                  '$secs',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.black26,
                    color: secs <= 10 ? AppColors.wrong : AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: QuestionView(
              key: ValueKey(s.current),
              question: s.current,
              options: s.options,
              removed: s.removed,
              picked: s.picked,
              onPick: _pick,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: ActionButton(
                  'حذف إجابتين',
                  icon: Icons.lightbulb,
                  primary: false,
                  onPressed: s.answered || s.hintUsed || s.timeUp
                      ? null
                      : _hint,
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
