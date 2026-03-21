import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class HangmanFigure extends StatelessWidget {
  final int wrongGuesses;
  final int maxWrongGuesses;

  const HangmanFigure({
    super.key,
    required this.wrongGuesses,
    this.maxWrongGuesses = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.cardColor,
          width: 2,
        ),
      ),
      child: CustomPaint(
        painter: HangmanPainter(wrongGuesses: wrongGuesses),
        size: const Size(168, 218),
      ),
    );
  }
}

class HangmanPainter extends CustomPainter {
  final int wrongGuesses;

  HangmanPainter({required this.wrongGuesses});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gallowsPaint = Paint()
      ..color = AppTheme.textSecondary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint bodyPaint = Paint()
      ..color = AppTheme.errorColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = size.width / 2;
    final baseY = size.height - 20;

    // Darağacı tabanı
    canvas.drawLine(
      Offset(20, baseY),
      Offset(size.width - 20, baseY),
      gallowsPaint,
    );

    // Dikey direk
    canvas.drawLine(
      Offset(50, baseY),
      Offset(50, 20),
      gallowsPaint,
    );

    // Üst yatay direk
    canvas.drawLine(
      const Offset(50, 20),
      Offset(center, 20),
      gallowsPaint,
    );

    // İp
    canvas.drawLine(
      Offset(center, 20),
      Offset(center, 45),
      gallowsPaint,
    );

    // Adam parçaları
    if (wrongGuesses >= 1) {
      // Kafa
      canvas.drawCircle(
        Offset(center, 65),
        20,
        bodyPaint,
      );
    }

    if (wrongGuesses >= 2) {
      // Gövde
      canvas.drawLine(
        Offset(center, 85),
        Offset(center, 140),
        bodyPaint,
      );
    }

    if (wrongGuesses >= 3) {
      // Sol kol
      canvas.drawLine(
        Offset(center, 100),
        Offset(center - 30, 130),
        bodyPaint,
      );
    }

    if (wrongGuesses >= 4) {
      // Sağ kol
      canvas.drawLine(
        Offset(center, 100),
        Offset(center + 30, 130),
        bodyPaint,
      );
    }

    if (wrongGuesses >= 5) {
      // Sol bacak
      canvas.drawLine(
        Offset(center, 140),
        Offset(center - 25, 185),
        bodyPaint,
      );
    }

    if (wrongGuesses >= 6) {
      // Sağ bacak
      canvas.drawLine(
        Offset(center, 140),
        Offset(center + 25, 185),
        bodyPaint,
      );

      // Üzgün yüz
      final facePaint = Paint()
        ..color = AppTheme.errorColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      // Gözler (X şeklinde)
      canvas.drawLine(
        Offset(center - 10, 58),
        Offset(center - 4, 64),
        facePaint,
      );
      canvas.drawLine(
        Offset(center - 10, 64),
        Offset(center - 4, 58),
        facePaint,
      );
      canvas.drawLine(
        Offset(center + 4, 58),
        Offset(center + 10, 64),
        facePaint,
      );
      canvas.drawLine(
        Offset(center + 4, 64),
        Offset(center + 10, 58),
        facePaint,
      );

      // Üzgün ağız
      final path = Path();
      path.moveTo(center - 8, 78);
      path.quadraticBezierTo(center, 72, center + 8, 78);
      canvas.drawPath(path, facePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HangmanPainter oldDelegate) {
    return oldDelegate.wrongGuesses != wrongGuesses;
  }
}
