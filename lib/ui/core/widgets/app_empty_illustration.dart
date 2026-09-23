import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/theme_ext.dart';

enum AppEmptyIllustrationType { content, search, favorites }

class AppEmptyIllustration extends StatelessWidget {
  const AppEmptyIllustration({super.key, required this.type});

  final AppEmptyIllustrationType type;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(96),
    painter: _EmptyIllustrationPainter(type: type, colors: context.colors),
  );
}

class _EmptyIllustrationPainter extends CustomPainter {
  const _EmptyIllustrationPainter({required this.type, required this.colors});

  final AppEmptyIllustrationType type;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 156, size.height / 136);
    canvas.save();
    canvas.translate(
      (size.width - 156 * scale) / 2,
      (size.height - 136 * scale) / 2,
    );
    canvas.scale(scale);
    final ink = Paint()
      ..color = colors.mutedForeground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final blue = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final paper = Paint()..color = colors.card;
    canvas.drawCircle(const Offset(78, 67), 52, Paint()..color = colors.accent);

    switch (type) {
      case AppEmptyIllustrationType.content:
        final sheet = Path()
          ..moveTo(62, 31)
          ..lineTo(94, 25)
          ..lineTo(102, 76)
          ..lineTo(70, 82)
          ..close();
        canvas.drawPath(sheet, paper);
        canvas.drawPath(sheet, ink);
        canvas.drawPath(
          Path()
            ..moveTo(72, 44)
            ..lineTo(87, 41)
            ..moveTo(74, 52)
            ..lineTo(89, 49),
          ink,
        );
        final tray = Path()
          ..moveTo(43, 68)
          ..lineTo(113, 68)
          ..lineTo(125, 92)
          ..lineTo(125, 115)
          ..lineTo(31, 115)
          ..lineTo(31, 92)
          ..close();
        canvas.drawPath(tray, paper);
        canvas.drawPath(tray, ink);
        canvas.drawPath(
          Path()
            ..moveTo(31, 92)
            ..lineTo(59, 92)
            ..lineTo(65, 102)
            ..lineTo(91, 102)
            ..lineTo(97, 92)
            ..lineTo(125, 92)
            ..moveTo(43, 68)
            ..lineTo(51, 85)
            ..moveTo(113, 68)
            ..lineTo(105, 85),
          ink,
        );
        canvas.drawLine(const Offset(119, 35), const Offset(119, 47), blue);
        canvas.drawLine(const Offset(113, 41), const Offset(125, 41), blue);
        canvas.drawCircle(
          const Offset(131, 73),
          2.5,
          Paint()..color = colors.primary,
        );
      case AppEmptyIllustrationType.search:
        final document = Path()
          ..moveTo(43, 28)
          ..lineTo(92, 28)
          ..lineTo(108, 44)
          ..lineTo(108, 109)
          ..lineTo(43, 109)
          ..close();
        canvas.drawPath(document, paper);
        canvas.drawPath(document, ink);
        canvas.drawPath(
          Path()
            ..moveTo(92, 28)
            ..lineTo(92, 44)
            ..lineTo(108, 44)
            ..moveTo(55, 46)
            ..lineTo(78, 46)
            ..moveTo(55, 59)
            ..lineTo(82, 59)
            ..moveTo(55, 72)
            ..lineTo(66, 72),
          ink,
        );
        canvas.drawCircle(const Offset(92, 83), 22, paper);
        canvas.drawCircle(const Offset(92, 83), 22, ink);
        canvas.drawLine(const Offset(85, 83), const Offset(99, 83), ink);
        canvas.drawLine(
          const Offset(108, 99),
          const Offset(125, 116),
          blue..strokeWidth = 5,
        );
        canvas.drawCircle(
          const Offset(122, 39),
          3,
          Paint()..color = colors.primary,
        );
      case AppEmptyIllustrationType.favorites:
        final back = Path()
          ..moveTo(60, 27)
          ..lineTo(109, 36)
          ..lineTo(94, 117)
          ..lineTo(71, 94)
          ..lineTo(44, 108)
          ..close();
        canvas.drawPath(back, paper);
        canvas.drawPath(back, ink);
        final bookmark = Path()
          ..moveTo(48, 27)
          ..lineTo(103, 27)
          ..lineTo(103, 107)
          ..lineTo(75.5, 88)
          ..lineTo(48, 107)
          ..close();
        canvas.drawPath(bookmark, paper);
        canvas.drawPath(bookmark, ink);
        canvas.drawPath(
          Path()
            ..moveTo(75.5, 44)
            ..lineTo(81, 55)
            ..lineTo(93, 57)
            ..lineTo(84, 65.5)
            ..lineTo(86, 77.5)
            ..lineTo(75.5, 71.5)
            ..lineTo(65, 77.5)
            ..lineTo(67, 65.5)
            ..lineTo(58, 57)
            ..lineTo(70, 55)
            ..close(),
          blue,
        );
        canvas.drawLine(const Offset(121, 29), const Offset(121, 39), blue);
        canvas.drawLine(const Offset(116, 34), const Offset(126, 34), blue);
        canvas.drawCircle(
          const Offset(30, 91),
          2.5,
          Paint()..color = colors.primary,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EmptyIllustrationPainter oldDelegate) =>
      type != oldDelegate.type || colors != oldDelegate.colors;
}
