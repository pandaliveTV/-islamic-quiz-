import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/question_repository.dart';
import '../widgets/ornaments.dart';
import '../widgets/theme.dart';
import 'home_screen.dart';

/// EliteP logo while the question bank loads.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final repo = context.read<QuestionRepository>();
    await Future.wait([
      repo.preloadAll(),
      Future<void>.delayed(const Duration(milliseconds: 1800)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IslamicBackground(
        child: Center(
          child: FadeTransition(
            opacity: _c,
            child: ScaleTransition(
              scale: Tween(
                begin: 0.85,
                end: 1.0,
              ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StarMedallion(
                    size: 120,
                    child: Text(
                      'E',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      'EliteP',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      'GAMES',
                      style: TextStyle(
                        letterSpacing: 8,
                        color: AppColors.goldSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
