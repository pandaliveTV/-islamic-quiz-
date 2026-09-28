import 'dart:math';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Eight-pointed star (Rub el Hizb style): two squares rotated 45°.
Path eightPointStar(Offset c, double r) {
  final path = Path();
  for (final start in [0.0, pi / 4]) {
    for (var i = 0; i < 4; i++) {
      final a = start + i * pi / 2;
      final p = c + Offset(cos(a), sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
  }
  return path;
}

/// Subtle geometric pattern painted once and cached (RepaintBoundary).
class _PatternPainter extends CustomPainter {
  const _PatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 64.0;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.gold.withValues(alpha: 0.07);
    final dot = Paint()..color = AppColors.gold.withValues(alpha: 0.06);
    for (var y = 0.0; y < size.height + cell; y += cell) {
      final row = (y / cell).round();
      for (
        var x = (row.isOdd ? cell / 2 : 0.0);
        x < size.width + cell;
        x += cell
      ) {
        final c = Offset(x, y);
        canvas.drawPath(eightPointStar(c, cell * 0.3), stroke);
        canvas.drawCircle(c, 2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Deep green gradient with a faint star pattern behind every screen.
class IslamicBackground extends StatelessWidget {
  final Widget child;
  const IslamicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.green, AppColors.deep],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: CustomPaint(painter: _PatternPainter())),
          child,
        ],
      ),
    );
  }
}

/// Star medallion used for the logo and headers.
class StarMedallion extends StatelessWidget {
  final double size;
  final Widget? child;
  const StarMedallion({super.key, this.size = 96, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MedallionPainter(),
        child: Center(child: child),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawPath(
      eightPointStar(c, r),
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.gold, Color(0xFFB8860B)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(c, r * 0.62, Paint()..color = AppColors.deep);
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.goldSoft,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Thin ornamental divider: line – star – line.
class OrnamentDivider extends StatelessWidget {
  final double width;
  const OrnamentDivider({super.key, this.width = 200});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: AppColors.gold.withValues(alpha: 0.5)),
    );
    return SizedBox(
      width: width,
      child: Row(
        children: [
          line,
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.star, size: 12, color: AppColors.gold),
          ),
          line,
        ],
      ),
    );
  }
}
