import 'package:flutter/material.dart';

/// Hand-drawn-style food illustrations painted from plain shapes. Drawn
/// rather than shipped as images so the app keeps its "no binary assets"
/// property, but with real silhouettes, shading and gloss so a child sees
/// an apple — not a generic glyph.
enum FoodKind {
  apple,
  banana,
  carrot,
  broccoli,
  grapes,
  fish,
  water,
  egg,
  milk,
  pizza,
  burger,
  donut,
  soda,
  candy,
  iceCream,
  cake,
  fries,
}

extension FoodKindInfo on FoodKind {
  bool get healthy => switch (this) {
        FoodKind.apple ||
        FoodKind.banana ||
        FoodKind.carrot ||
        FoodKind.broccoli ||
        FoodKind.grapes ||
        FoodKind.fish ||
        FoodKind.water ||
        FoodKind.egg ||
        FoodKind.milk =>
          true,
        _ => false,
      };

  String get label => switch (this) {
        FoodKind.apple => 'تفاحة',
        FoodKind.banana => 'موزة',
        FoodKind.carrot => 'جزرة',
        FoodKind.broccoli => 'بروكلي',
        FoodKind.grapes => 'عنب',
        FoodKind.fish => 'سمك',
        FoodKind.water => 'ماء',
        FoodKind.egg => 'بيضة',
        FoodKind.milk => 'حليب',
        FoodKind.pizza => 'بيتزا',
        FoodKind.burger => 'برجر',
        FoodKind.donut => 'دونات',
        FoodKind.soda => 'مشروب غازي',
        FoodKind.candy => 'حلوى',
        FoodKind.iceCream => 'آيس كريم',
        FoodKind.cake => 'كعكة',
        FoodKind.fries => 'بطاطس مقلية',
      };
}

class FoodArt extends StatelessWidget {
  final FoodKind kind;
  final double size;
  const FoodArt({super.key, required this.kind, this.size = 64});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size), painter: _FoodPainter(kind));
}

// Palette — warm and saturated, so items stay readable on the dark
// night-sky background the games sit on.
const _leaf = Color(0xFF5FAE58);
const _leafDeep = Color(0xFF3F8A44);
const _stem = Color(0xFF7A4A2B);
const _ink = Color(0xFF3A2A1E);

class _FoodPainter extends CustomPainter {
  final FoodKind kind;
  _FoodPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    switch (kind) {
      case FoodKind.apple:
        _apple(canvas);
      case FoodKind.banana:
        _banana(canvas);
      case FoodKind.carrot:
        _carrot(canvas);
      case FoodKind.broccoli:
        _broccoli(canvas);
      case FoodKind.grapes:
        _grapes(canvas);
      case FoodKind.fish:
        _fish(canvas);
      case FoodKind.water:
        _water(canvas);
      case FoodKind.egg:
        _egg(canvas);
      case FoodKind.milk:
        _milk(canvas);
      case FoodKind.pizza:
        _pizza(canvas);
      case FoodKind.burger:
        _burger(canvas);
      case FoodKind.donut:
        _donut(canvas);
      case FoodKind.soda:
        _soda(canvas);
      case FoodKind.candy:
        _candy(canvas);
      case FoodKind.iceCream:
        _iceCream(canvas);
      case FoodKind.cake:
        _cake(canvas);
      case FoodKind.fries:
        _fries(canvas);
    }
    canvas.restore();
  }

  Paint _fill(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  Paint _grad(Color light, Color dark, Rect r) => Paint()
    ..isAntiAlias = true
    ..shader = RadialGradient(center: const Alignment(-0.35, -0.45), colors: [light, dark]).createShader(r);

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  /// Soft white highlight — the single touch that makes flat shapes read as
  /// rounded objects rather than stickers.
  void _gloss(Canvas canvas, double cx, double cy, double rx, double ry, [double a = 0.32]) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      _fill(Colors.white.withValues(alpha: a)),
    );
  }

  void _apple(Canvas canvas) {
    final r = Rect.fromLTWH(10, 24, 80, 72);
    final body = Path()
      ..addOval(Rect.fromCircle(center: const Offset(37, 60), radius: 27))
      ..addOval(Rect.fromCircle(center: const Offset(63, 60), radius: 27));
    canvas.drawPath(body, _grad(const Color(0xFFEE6A5E), const Color(0xFFB8302A), r));
    // Dip between the two lobes.
    canvas.drawPath(
      Path()
        ..moveTo(42, 36)
        ..quadraticBezierTo(50, 42, 58, 36)
        ..quadraticBezierTo(50, 30, 42, 36)
        ..close(),
      _fill(const Color(0xFFB8302A).withValues(alpha: 0.35)),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(47, 14, 6, 22), const Radius.circular(3)), _fill(_stem));
    final leaf = Path()
      ..moveTo(53, 22)
      ..quadraticBezierTo(76, 8, 80, 26)
      ..quadraticBezierTo(64, 34, 53, 22)
      ..close();
    canvas.drawPath(leaf, _fill(_leaf));
    canvas.drawLine(const Offset(57, 22), const Offset(76, 21), _stroke(_leafDeep, 1.6));
    _gloss(canvas, 32, 48, 9, 13);
  }

  void _banana(Canvas canvas) {
    final p = Path()
      ..moveTo(16, 24)
      ..cubicTo(12, 62, 38, 88, 82, 80)
      ..cubicTo(72, 70, 62, 60, 56, 44)
      ..cubicTo(48, 26, 34, 18, 16, 24)
      ..close();
    canvas.drawPath(p, _grad(const Color(0xFFF9DE76), const Color(0xFFD9A93A), const Rect.fromLTWH(10, 18, 78, 70)));
    canvas.drawPath(
      Path()
        ..moveTo(24, 32)
        ..cubicTo(26, 58, 44, 74, 68, 74),
      _stroke(Colors.white.withValues(alpha: 0.45), 3.5),
    );
    canvas.drawCircle(const Offset(17, 24), 5, _fill(const Color(0xFF7A5E2B)));
    canvas.drawCircle(const Offset(82, 80), 5, _fill(const Color(0xFF7A5E2B)));
  }

  void _carrot(Canvas canvas) {
    final body = Path()
      ..moveTo(50, 94)
      ..lineTo(31, 38)
      ..quadraticBezierTo(50, 30, 69, 38)
      ..close();
    canvas.drawPath(body, _grad(const Color(0xFFF29A55), const Color(0xFFC96525), const Rect.fromLTWH(28, 30, 44, 64)));
    for (final y in [50.0, 62.0, 74.0]) {
      final half = (69 - 31) / 2 * (1 - (y - 38) / 56) * 0.72;
      canvas.drawLine(Offset(50 - half, y), Offset(50 - half + 8, y - 4), _stroke(const Color(0xFFB4551D).withValues(alpha: 0.65), 2.4));
    }
    for (final a in [-0.5, 0.0, 0.5]) {
      canvas.save();
      canvas.translate(50, 36);
      canvas.rotate(a);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-9, -18, 0, -30)
          ..quadraticBezierTo(9, -18, 0, 0)
          ..close(),
        _fill(a == 0.0 ? _leaf : _leafDeep),
      );
      canvas.restore();
    }
  }

  void _broccoli(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(41, 54, 18, 40), const Radius.circular(8)),
      _fill(const Color(0xFFA7C96A)),
    );
    final r = const Rect.fromLTWH(12, 12, 76, 56);
    for (final c in [
      const Offset(32, 44),
      const Offset(68, 44),
      const Offset(50, 30),
      const Offset(40, 26),
      const Offset(60, 26),
      const Offset(50, 50),
    ]) {
      canvas.drawCircle(c, 19, _grad(const Color(0xFF6CBF6B), _leafDeep, r));
    }
    canvas.drawCircle(const Offset(40, 28), 6, _fill(Colors.white.withValues(alpha: 0.22)));
  }

  void _grapes(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(47, 12, 6, 16), const Radius.circular(3)), _fill(_stem));
    canvas.drawPath(
      Path()
        ..moveTo(52, 20)
        ..quadraticBezierTo(74, 8, 78, 24)
        ..quadraticBezierTo(62, 30, 52, 20)
        ..close(),
      _fill(_leaf),
    );
    final r = const Rect.fromLTWH(18, 24, 64, 68);
    const centers = [
      Offset(35, 42), Offset(53, 40), Offset(69, 48),
      Offset(28, 58), Offset(45, 58), Offset(62, 62),
      Offset(37, 74), Offset(54, 76), Offset(46, 88),
    ];
    for (final c in centers) {
      canvas.drawCircle(c, 12, _grad(const Color(0xFFA98BDE), const Color(0xFF6B4FA0), r));
    }
    for (final c in centers) {
      canvas.drawCircle(Offset(c.dx - 4, c.dy - 4), 3.2, _fill(Colors.white.withValues(alpha: 0.35)));
    }
  }

  void _fish(Canvas canvas) {
    final tail = Path()
      ..moveTo(76, 50)
      ..lineTo(96, 30)
      ..lineTo(92, 50)
      ..lineTo(96, 70)
      ..close();
    canvas.drawPath(tail, _fill(const Color(0xFF3E8E9C)));
    canvas.drawOval(
      const Rect.fromLTWH(6, 26, 80, 48),
      _grad(const Color(0xFF8FD7E0), const Color(0xFF3E8E9C), const Rect.fromLTWH(6, 26, 80, 48)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(40, 28)
        ..quadraticBezierTo(50, 12, 62, 30)
        ..close(),
      _fill(const Color(0xFF3E8E9C)),
    );
    canvas.drawCircle(const Offset(24, 44), 7, _fill(Colors.white));
    canvas.drawCircle(const Offset(23, 45), 3.4, _fill(_ink));
    canvas.drawPath(
      Path()
        ..moveTo(54, 44)
        ..quadraticBezierTo(64, 50, 54, 58),
      _stroke(Colors.white.withValues(alpha: 0.45), 3),
    );
  }

  void _water(Canvas canvas) {
    final p = Path()
      ..moveTo(50, 10)
      ..cubicTo(72, 38, 82, 54, 82, 64)
      ..cubicTo(82, 82, 68, 94, 50, 94)
      ..cubicTo(32, 94, 18, 82, 18, 64)
      ..cubicTo(18, 54, 28, 38, 50, 10)
      ..close();
    canvas.drawPath(p, _grad(const Color(0xFF9BD8F5), const Color(0xFF3F8FC4), const Rect.fromLTWH(18, 10, 64, 84)));
    canvas.drawPath(
      Path()
        ..moveTo(35, 62)
        ..quadraticBezierTo(31, 76, 42, 84),
      _stroke(Colors.white.withValues(alpha: 0.6), 5),
    );
  }

  void _egg(Canvas canvas) {
    final p = Path()
      ..moveTo(50, 10)
      ..cubicTo(72, 10, 84, 42, 84, 62)
      ..cubicTo(84, 82, 69, 94, 50, 94)
      ..cubicTo(31, 94, 16, 82, 16, 62)
      ..cubicTo(16, 42, 28, 10, 50, 10)
      ..close();
    canvas.drawPath(p, _grad(Colors.white, const Color(0xFFE4D9C2), const Rect.fromLTWH(16, 10, 68, 84)));
    canvas.drawCircle(const Offset(50, 60), 15, _fill(const Color(0xFFF3C24B)));
    canvas.drawCircle(const Offset(45, 55), 5, _fill(Colors.white.withValues(alpha: 0.4)));
  }

  void _milk(Canvas canvas) {
    final carton = Path()
      ..moveTo(26, 34)
      ..lineTo(50, 14)
      ..lineTo(74, 34)
      ..lineTo(74, 92)
      ..lineTo(26, 92)
      ..close();
    canvas.drawPath(carton, _grad(Colors.white, const Color(0xFFDDD6C6), const Rect.fromLTWH(26, 14, 48, 78)));
    canvas.drawRect(const Rect.fromLTWH(26, 52, 48, 20), _fill(const Color(0xFF6BA8E0)));
    canvas.drawPath(
      Path()
        ..moveTo(50, 56)
        ..cubicTo(58, 63, 60, 66, 60, 68)
        ..cubicTo(60, 72, 56, 75, 50, 75)
        ..cubicTo(44, 75, 40, 72, 40, 68)
        ..cubicTo(40, 66, 42, 63, 50, 56)
        ..close(),
      _fill(Colors.white),
    );
    canvas.drawLine(const Offset(50, 14), const Offset(50, 34), _stroke(const Color(0xFFC9C0AC), 2));
  }

  void _pizza(Canvas canvas) {
    final slice = Path()
      ..moveTo(50, 10)
      ..lineTo(15, 76)
      ..quadraticBezierTo(50, 92, 85, 76)
      ..close();
    canvas.drawPath(slice, _grad(const Color(0xFFF8DE97), const Color(0xFFE0A94F), const Rect.fromLTWH(15, 10, 70, 82)));
    canvas.drawPath(
      Path()
        ..moveTo(15, 76)
        ..quadraticBezierTo(50, 92, 85, 76),
      _stroke(const Color(0xFFD08E3F), 13),
    );
    for (final c in [const Offset(44, 44), const Offset(60, 58), const Offset(36, 64)]) {
      canvas.drawCircle(c, 7.5, _fill(const Color(0xFFD1543F)));
      canvas.drawCircle(Offset(c.dx - 2, c.dy - 2), 2.4, _fill(const Color(0xFFE87B67)));
    }
  }

  void _burger(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndCorners(const Rect.fromLTWH(14, 72, 72, 16),
          bottomLeft: const Radius.circular(14), bottomRight: const Radius.circular(14)),
      _fill(const Color(0xFFCE9450)),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(11, 56, 78, 18), const Radius.circular(7)), _fill(const Color(0xFF8A5232)));
    final lettuce = Path()..moveTo(11, 56);
    for (double x = 11; x <= 89; x += 13) {
      lettuce.quadraticBezierTo(x + 6.5, 46, x + 13, 56);
    }
    lettuce
      ..lineTo(89, 58)
      ..lineTo(11, 58)
      ..close();
    canvas.drawPath(lettuce, _fill(const Color(0xFF6FBF5E)));
    final top = Path()
      ..moveTo(12, 48)
      ..cubicTo(12, 20, 88, 20, 88, 48)
      ..close();
    canvas.drawPath(top, _grad(const Color(0xFFEFBC77), const Color(0xFFCE9450), const Rect.fromLTWH(12, 20, 76, 28)));
    for (final c in [const Offset(35, 36), const Offset(52, 31), const Offset(68, 37)]) {
      canvas.drawOval(Rect.fromCenter(center: c, width: 7, height: 4), _fill(const Color(0xFFF8ECD2)));
    }
  }

  void _donut(Canvas canvas) {
    canvas.drawCircle(const Offset(50, 54), 30, _stroke(const Color(0xFFE3B071), 22));
    canvas.drawCircle(const Offset(50, 51), 30, _stroke(const Color(0xFFEE7FA8), 17));
    const sprinkles = [
      [30.0, 34.0, -0.6], [52.0, 24.0, 0.3], [72.0, 36.0, 0.9],
      [24.0, 58.0, 0.4], [78.0, 60.0, -0.4], [40.0, 78.0, 0.8], [64.0, 76.0, -0.9],
    ];
    const colors = [Color(0xFFF8E17C), Color(0xFF7FD1C4), Colors.white, Color(0xFFF8E17C), Color(0xFF7FD1C4), Colors.white, Color(0xFFF8E17C)];
    for (int i = 0; i < sprinkles.length; i++) {
      canvas.save();
      canvas.translate(sprinkles[i][0], sprinkles[i][1]);
      canvas.rotate(sprinkles[i][2]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -1.8, 10, 3.6), const Radius.circular(2)),
        _fill(colors[i]),
      );
      canvas.restore();
    }
  }

  void _soda(Canvas canvas) {
    canvas.drawLine(const Offset(64, 12), const Offset(56, 34), _stroke(const Color(0xFFF3CF7A), 7));
    final cup = Path()
      ..moveTo(28, 30)
      ..lineTo(36, 92)
      ..lineTo(64, 92)
      ..lineTo(72, 30)
      ..close();
    canvas.drawPath(cup, _grad(const Color(0xFFE8756F), const Color(0xFFB8302A), const Rect.fromLTWH(28, 30, 44, 62)));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 24, 52, 12), const Radius.circular(6)), _fill(const Color(0xFFE9E5DC)));
    canvas.drawRect(const Rect.fromLTWH(31, 52, 38, 14), _fill(Colors.white.withValues(alpha: 0.75)));
    canvas.drawCircle(const Offset(50, 59), 5, _fill(const Color(0xFFB8302A)));
  }

  void _candy(Canvas canvas) {
    for (final dir in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(50 + dir * 20, 50)
          ..lineTo(50 + dir * 44, 30)
          ..lineTo(50 + dir * 44, 70)
          ..close(),
        _fill(const Color(0xFFF3A9C0)),
      );
    }
    canvas.drawCircle(const Offset(50, 50), 24, _grad(const Color(0xFFFCA6C6), const Color(0xFFDE5A8E), const Rect.fromLTWH(26, 26, 48, 48)));
    canvas.drawPath(
      Path()
        ..moveTo(36, 44)
        ..quadraticBezierTo(50, 34, 64, 44),
      _stroke(Colors.white.withValues(alpha: 0.6), 5),
    );
  }

  void _iceCream(Canvas canvas) {
    final cone = Path()
      ..moveTo(30, 52)
      ..lineTo(50, 96)
      ..lineTo(70, 52)
      ..close();
    canvas.drawPath(cone, _fill(const Color(0xFFD9A567)));
    for (final d in [0.0, 1.0, 2.0]) {
      canvas.drawLine(Offset(34 + d * 10, 56), Offset(48 + d * 10, 82), _stroke(const Color(0xFFB07F44).withValues(alpha: 0.6), 2));
    }
    canvas.drawCircle(const Offset(38, 44), 18, _grad(const Color(0xFFFBC0D4), const Color(0xFFE87BA6), const Rect.fromLTWH(20, 26, 36, 36)));
    canvas.drawCircle(const Offset(62, 44), 18, _grad(const Color(0xFFFBEBA8), const Color(0xFFE8C455), const Rect.fromLTWH(44, 26, 36, 36)));
    canvas.drawCircle(const Offset(50, 28), 17, _grad(const Color(0xFFCFEAD8), const Color(0xFF7FC49A), const Rect.fromLTWH(33, 11, 34, 34)));
    canvas.drawCircle(const Offset(50, 12), 5, _fill(const Color(0xFFD9453C)));
  }

  void _cake(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 62, 64, 30), const Radius.circular(6)), _fill(const Color(0xFFF0D6A0)));
    canvas.drawRect(const Rect.fromLTWH(18, 70, 64, 8), _fill(const Color(0xFFD98FA8)));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 44, 68, 22), const Radius.circular(8)), _fill(const Color(0xFFF8F0E0)));
    final drip = Path()..moveTo(16, 58);
    for (double x = 16; x <= 84; x += 17) {
      drip.quadraticBezierTo(x + 8.5, 72, x + 17, 58);
    }
    drip
      ..lineTo(84, 50)
      ..lineTo(16, 50)
      ..close();
    canvas.drawPath(drip, _fill(const Color(0xFFF8F0E0)));
    canvas.drawCircle(const Offset(50, 34), 9, _fill(const Color(0xFFD9453C)));
    canvas.drawPath(
      Path()
        ..moveTo(50, 26)
        ..quadraticBezierTo(58, 16, 64, 18),
      _stroke(const Color(0xFF5FAE58), 3),
    );
  }

  void _fries(Canvas canvas) {
    const fry = Color(0xFFF6D272);
    for (final f in [
      [30.0, 20.0, -0.22], [42.0, 12.0, -0.06], [56.0, 14.0, 0.08], [68.0, 24.0, 0.26], [49.0, 22.0, 0.0],
    ]) {
      canvas.save();
      canvas.translate(f[0], f[1]);
      canvas.rotate(f[2]);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-6, 0, 12, 52), const Radius.circular(4)), _fill(fry));
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 4, 4, 40), const Radius.circular(2)),
          _fill(Colors.white.withValues(alpha: 0.35)));
      canvas.restore();
    }
    final carton = Path()
      ..moveTo(26, 52)
      ..lineTo(34, 94)
      ..lineTo(66, 94)
      ..lineTo(74, 52)
      ..close();
    canvas.drawPath(carton, _grad(const Color(0xFFE8756F), const Color(0xFFB8302A), const Rect.fromLTWH(26, 52, 48, 42)));
    canvas.drawRect(const Rect.fromLTWH(33, 66, 34, 12), _fill(Colors.white.withValues(alpha: 0.7)));
  }

  @override
  bool shouldRepaint(covariant _FoodPainter old) => old.kind != kind;
}
