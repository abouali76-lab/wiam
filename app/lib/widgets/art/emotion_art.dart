import 'dart:math';
import 'package:flutter/material.dart';

/// Expressive faces for the feelings game. Each emotion changes eyes,
/// brows and mouth together — a child reads the whole face, not one detail,
/// so the differences have to be legible at a glance.
enum Emotion { happy, sad, angry, scared, surprised, shy, sleepy, proud }

extension EmotionInfo on Emotion {
  String get label => switch (this) {
        Emotion.happy => 'سعيد',
        Emotion.sad => 'حزين',
        Emotion.angry => 'غاضب',
        Emotion.scared => 'خائف',
        Emotion.surprised => 'متفاجئ',
        Emotion.shy => 'خجول',
        Emotion.sleepy => 'نعسان',
        Emotion.proud => 'فخور',
      };

  /// A everyday situation a child can recognise, used as the prompt.
  String get situation => switch (this) {
        Emotion.happy => 'صديقك شاركك لعبته المفضلة',
        Emotion.sad => 'انكسرت لعبتك التي تحبها',
        Emotion.angry => 'أحدهم أخذ دورك دون إذن',
        Emotion.scared => 'سمعت صوتاً عالياً في الظلام',
        Emotion.surprised => 'وجدت هدية لم تتوقعها',
        Emotion.shy => 'طُلب منك التحدث أمام الصف',
        Emotion.sleepy => 'تأخر الوقت وأنت في السرير',
        Emotion.proud => 'أنهيت واجبك كاملاً بنفسك',
      };

  Color get color => switch (this) {
        Emotion.happy => const Color(0xFFF3C24B),
        Emotion.sad => const Color(0xFF7FA8DE),
        Emotion.angry => const Color(0xFFE8756F),
        Emotion.scared => const Color(0xFFB59BE0),
        Emotion.surprised => const Color(0xFF7FD1C4),
        Emotion.shy => const Color(0xFFF3A9C0),
        Emotion.sleepy => const Color(0xFF9AA4C8),
        Emotion.proud => const Color(0xFF8FC97E),
      };
}

class EmotionFace extends StatelessWidget {
  final Emotion emotion;
  final double size;
  const EmotionFace({super.key, required this.emotion, this.size = 72});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size), painter: _FacePainter(emotion));
}

const _ink = Color(0xFF3A2E22);

class _FacePainter extends CustomPainter {
  final Emotion e;
  _FacePainter(this.e);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final base = e.color;
    canvas.drawCircle(
      const Offset(50, 50),
      44,
      Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [Color.lerp(base, Colors.white, 0.4)!, base],
        ).createShader(Rect.fromCircle(center: const Offset(50, 50), radius: 46)),
    );

    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final solid = Paint()
      ..color = _ink
      ..isAntiAlias = true;

    _eyes(canvas, line, solid);
    _brows(canvas, line);
    _mouth(canvas, line, solid);
    _extras(canvas, line);

    canvas.restore();
  }

  void _eyes(Canvas canvas, Paint line, Paint solid) {
    const ly = 44.0, dx = 16.0;
    switch (e) {
      case Emotion.happy || Emotion.proud:
        // Cheerful upward arcs.
        for (final s in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(50 + s * dx - 7, ly + 2)
              ..quadraticBezierTo(50 + s * dx, ly - 9, 50 + s * dx + 7, ly + 2),
            line,
          );
        }
      case Emotion.sleepy:
        for (final s in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(50 + s * dx - 7, ly)
              ..quadraticBezierTo(50 + s * dx, ly + 7, 50 + s * dx + 7, ly),
            line,
          );
        }
      case Emotion.surprised:
        for (final s in [-1.0, 1.0]) {
          canvas.drawCircle(Offset(50 + s * dx, ly), 7.5, Paint()..color = Colors.white);
          canvas.drawCircle(Offset(50 + s * dx, ly), 4.2, solid);
        }
      case Emotion.scared:
        for (final s in [-1.0, 1.0]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(50 + s * dx, ly), width: 13, height: 16), Paint()..color = Colors.white);
          canvas.drawCircle(Offset(50 + s * dx, ly + 2), 4, solid);
        }
      default:
        for (final s in [-1.0, 1.0]) {
          canvas.drawCircle(Offset(50 + s * dx, ly), 5, solid);
        }
    }
  }

  void _brows(Canvas canvas, Paint line) {
    const by = 30.0, dx = 16.0;
    switch (e) {
      case Emotion.angry:
        canvas.drawLine(const Offset(50 - dx - 8, by - 3), const Offset(50 - dx + 7, by + 4), line);
        canvas.drawLine(const Offset(50 + dx + 8, by - 3), const Offset(50 + dx - 7, by + 4), line);
      case Emotion.sad || Emotion.scared:
        canvas.drawLine(const Offset(50 - dx - 8, by + 4), const Offset(50 - dx + 7, by - 3), line);
        canvas.drawLine(const Offset(50 + dx + 8, by + 4), const Offset(50 + dx - 7, by - 3), line);
      case Emotion.surprised:
        for (final s in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(50 + s * dx - 8, by)
              ..quadraticBezierTo(50 + s * dx, by - 7, 50 + s * dx + 8, by),
            line,
          );
        }
      default:
        break;
    }
  }

  void _mouth(Canvas canvas, Paint line, Paint solid) {
    const my = 64.0;
    switch (e) {
      case Emotion.happy:
        canvas.drawPath(
          Path()
            ..moveTo(32, my - 2)
            ..quadraticBezierTo(50, my + 20, 68, my - 2),
          line,
        );
      case Emotion.proud:
        canvas.drawPath(
          Path()
            ..moveTo(34, my)
            ..quadraticBezierTo(50, my + 16, 66, my)
            ..close(),
          solid,
        );
      case Emotion.sad:
        canvas.drawPath(
          Path()
            ..moveTo(34, my + 10)
            ..quadraticBezierTo(50, my - 6, 66, my + 10),
          line,
        );
      case Emotion.angry:
        canvas.drawPath(
          Path()
            ..moveTo(34, my + 8)
            ..quadraticBezierTo(50, my - 4, 66, my + 8),
          line,
        );
      case Emotion.surprised:
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, my + 4), width: 18, height: 22), solid);
      case Emotion.scared:
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, my + 4), width: 15, height: 18), solid);
      case Emotion.shy:
        canvas.drawPath(
          Path()
            ..moveTo(42, my + 2)
            ..quadraticBezierTo(50, my + 10, 58, my + 2),
          line,
        );
      case Emotion.sleepy:
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, my + 4), width: 12, height: 15), solid);
    }
  }

  void _extras(Canvas canvas, Paint line) {
    switch (e) {
      case Emotion.shy:
        final blush = Paint()..color = const Color(0xFFE05A7A).withValues(alpha: 0.45);
        canvas.drawOval(Rect.fromCenter(center: const Offset(24, 58), width: 17, height: 11), blush);
        canvas.drawOval(Rect.fromCenter(center: const Offset(76, 58), width: 17, height: 11), blush);
      case Emotion.sad:
        // A single tear.
        canvas.drawPath(
          Path()
            ..moveTo(34, 52)
            ..cubicTo(40, 62, 41, 66, 38, 70)
            ..cubicTo(34, 74, 28, 70, 30, 64)
            ..cubicTo(31, 60, 32, 56, 34, 52)
            ..close(),
          Paint()..color = const Color(0xFF4E8FD1),
        );
      case Emotion.sleepy:
        for (int i = 0; i < 3; i++) {
          final s = 7.0 + i * 3;
          final x = 74.0 + i * 8;
          final y = 26.0 - i * 9;
          canvas.drawPath(
            Path()
              ..moveTo(x - s / 2, y - s / 2)
              ..lineTo(x + s / 2, y - s / 2)
              ..lineTo(x - s / 2, y + s / 2)
              ..lineTo(x + s / 2, y + s / 2),
            Paint()
              ..color = _ink.withValues(alpha: 0.55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.6
              ..strokeCap = StrokeCap.round,
          );
        }
      case Emotion.angry:
        for (int i = 0; i < 3; i++) {
          final a = -0.9 + i * 0.5;
          canvas.drawLine(
            Offset(50 + cos(a) * 50, 50 + sin(a) * 50),
            Offset(50 + cos(a) * 60, 50 + sin(a) * 60),
            line,
          );
        }
      case Emotion.proud:
        // Small sparkle above the head.
        canvas.drawPath(
          Path()
            ..moveTo(50, 0)
            ..lineTo(54, 8)
            ..lineTo(62, 5)
            ..lineTo(57, 12),
          Paint()
            ..color = const Color(0xFFF3C24B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) => old.e != e;
}
