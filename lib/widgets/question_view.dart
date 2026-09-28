import 'package:flutter/material.dart';

import '../data/models.dart';
import 'theme.dart';

/// Question card with its four options. Stateless: the session owns state.
class QuestionView extends StatelessWidget {
  final Question question;
  final List<String> options;
  final Set<String> removed;
  final String? picked;
  final ValueChanged<String> onPick;

  const QuestionView({
    super.key,
    required this.question,
    required this.options,
    required this.removed,
    required this.picked,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold, width: 2),
          ),
          child: Text(
            question.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.deep,
              fontSize: 19,
              height: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionButton(
              text: o,
              state: _stateOf(o),
              onTap: picked == null && !removed.contains(o)
                  ? () => onPick(o)
                  : null,
            ),
          ),
      ],
    );
  }

  _OptionState _stateOf(String o) {
    if (removed.contains(o)) return _OptionState.removed;
    if (picked == null) return _OptionState.idle;
    if (o == question.correct) return _OptionState.correct;
    if (o == picked) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, correct, wrong, dimmed, removed }

class _OptionButton extends StatelessWidget {
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;
  const _OptionButton({required this.text, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (state) {
      _OptionState.idle => (AppColors.teal, AppColors.cream, null),
      _OptionState.correct => (
        AppColors.correct,
        Colors.white,
        Icons.check_circle,
      ),
      _OptionState.wrong => (AppColors.wrong, Colors.white, Icons.cancel),
      _OptionState.dimmed => (
        AppColors.teal.withValues(alpha: 0.4),
        Colors.white54,
        null,
      ),
      _OptionState.removed => (
        Colors.black.withValues(alpha: 0.2),
        Colors.white24,
        null,
      ),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: state == _OptionState.idle
              ? AppColors.gold.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state == _OptionState.removed ? '—' : text,
                      style: TextStyle(
                        color: fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: state == _OptionState.removed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (icon != null) Icon(icon, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Short explanation / source shown after answering.
class ExplanationCard extends StatelessWidget {
  final bool correct;
  final Question question;
  const ExplanationCard({
    super.key,
    required this.correct,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (correct ? AppColors.correct : AppColors.wrong).withValues(
            alpha: 0.8,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.info,
                color: correct ? AppColors.correct : AppColors.wrong,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  correct
                      ? 'إجابة صحيحة'
                      : 'الإجابة الصحيحة: ${question.correct}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            question.explanation,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}
