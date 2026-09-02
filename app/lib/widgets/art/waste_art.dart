import 'package:flutter/material.dart';

/// Recycling items and their bins. Colours follow the common convention the
/// list described (أزرق للورق، أصفر للبلاستيك، أخضر للزجاج) so what the
/// child learns here matches the bins they may actually see.
enum WasteBin { paper, plastic, glass }

extension WasteBinInfo on WasteBin {
  String get label => switch (this) {
        WasteBin.paper => 'ورق',
        WasteBin.plastic => 'بلاستيك',
        WasteBin.glass => 'زجاج',
      };

  Color get color => switch (this) {
        WasteBin.paper => const Color(0xFF5B8FD1),
        WasteBin.plastic => const Color(0xFFE0A93F),
        WasteBin.glass => const Color(0xFF5FAE72),
      };
}

enum WasteKind { newspaper, box, notebook, bottle, bag, cup, jar, glassBottle, glassCup }

extension WasteKindInfo on WasteKind {
  WasteBin get bin => switch (this) {
        WasteKind.newspaper || WasteKind.box || WasteKind.notebook => WasteBin.paper,
        WasteKind.bottle || WasteKind.bag || WasteKind.cup => WasteBin.plastic,
        WasteKind.jar || WasteKind.glassBottle || WasteKind.glassCup => WasteBin.glass,
      };

  String get label => switch (this) {
        WasteKind.newspaper => 'جريدة',
        WasteKind.box => 'صندوق كرتون',
        WasteKind.notebook => 'دفتر',
        WasteKind.bottle => 'قارورة بلاستيك',
        WasteKind.bag => 'كيس بلاستيك',
        WasteKind.cup => 'كوب بلاستيك',
        WasteKind.jar => 'مرطبان زجاج',
        WasteKind.glassBottle => 'زجاجة',
        WasteKind.glassCup => 'كأس زجاج',
      };
}

class WasteArt extends StatelessWidget {
  final WasteKind kind;
  final double size;
  const WasteArt({super.key, required this.kind, this.size = 64});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size), painter: _WastePainter(kind));
}

class _WastePainter extends CustomPainter {
  final WasteKind kind;
  _WastePainter(this.kind);

  Paint _fill(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    switch (kind) {
      case WasteKind.newspaper:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 22, 68, 58), const Radius.circular(4)), _fill(const Color(0xFFF2EDE0)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(22, 16, 62, 58), const Radius.circular(4)), _fill(Colors.white));
        canvas.drawRect(const Rect.fromLTWH(29, 24, 48, 12), _fill(const Color(0xFF4A4A5C)));
        for (int i = 0; i < 5; i++) {
          canvas.drawLine(Offset(29, 44.0 + i * 8), Offset(i.isEven ? 77 : 66, 44.0 + i * 8), _stroke(const Color(0xFFB9BACB), 3));
        }
      case WasteKind.box:
        canvas.drawPath(
          Path()
            ..moveTo(18, 36)
            ..lineTo(50, 22)
            ..lineTo(82, 36)
            ..lineTo(82, 82)
            ..lineTo(18, 82)
            ..close(),
          _fill(const Color(0xFFCE9450)),
        );
        canvas.drawPath(
          Path()
            ..moveTo(18, 36)
            ..lineTo(50, 48)
            ..lineTo(82, 36),
          _stroke(const Color(0xFF9C6C34), 3.5),
        );
        canvas.drawLine(const Offset(50, 48), const Offset(50, 82), _stroke(const Color(0xFF9C6C34), 3.5));
      case WasteKind.notebook:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 16, 56, 68), const Radius.circular(6)), _fill(const Color(0xFF6BA8E0)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(34, 16, 46, 68), const Radius.circular(4)), _fill(Colors.white));
        for (int i = 0; i < 4; i++) {
          canvas.drawLine(Offset(41, 34.0 + i * 13), Offset(72, 34.0 + i * 13), _stroke(const Color(0xFFC7C9DA), 3));
        }
        for (int i = 0; i < 4; i++) {
          canvas.drawCircle(Offset(29, 28.0 + i * 16), 3.4, _fill(const Color(0xFF3E6E9C)));
        }
      case WasteKind.bottle:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(42, 10, 16, 12), const Radius.circular(3)), _fill(const Color(0xFF4E9BD1)));
        canvas.drawPath(
          Path()
            ..moveTo(43, 22)
            ..lineTo(43, 30)
            ..cubicTo(34, 36, 32, 42, 32, 52)
            ..lineTo(32, 82)
            ..cubicTo(32, 88, 36, 90, 50, 90)
            ..cubicTo(64, 90, 68, 88, 68, 82)
            ..lineTo(68, 52)
            ..cubicTo(68, 42, 66, 36, 57, 30)
            ..lineTo(57, 22)
            ..close(),
          _fill(const Color(0xFFB6DCF0).withValues(alpha: 0.92)),
        );
        canvas.drawRect(const Rect.fromLTWH(32, 56, 36, 14), _fill(const Color(0xFF7FD1C4)));
        canvas.drawLine(const Offset(39, 40), const Offset(39, 78), _stroke(Colors.white.withValues(alpha: 0.75), 4));
      case WasteKind.bag:
        canvas.drawPath(
          Path()
            ..moveTo(26, 34)
            ..lineTo(74, 34)
            ..lineTo(80, 88)
            ..lineTo(20, 88)
            ..close(),
          _fill(const Color(0xFFE2E6EE).withValues(alpha: 0.95)),
        );
        canvas.drawPath(
          Path()
            ..moveTo(36, 34)
            ..cubicTo(36, 16, 64, 16, 64, 34),
          _stroke(const Color(0xFFB3BBCB), 5),
        );
        canvas.drawLine(const Offset(38, 46), const Offset(42, 80), _stroke(Colors.white, 4));
      case WasteKind.cup:
        canvas.drawPath(
          Path()
            ..moveTo(28, 26)
            ..lineTo(36, 88)
            ..lineTo(64, 88)
            ..lineTo(72, 26)
            ..close(),
          _fill(const Color(0xFFE2E6EE).withValues(alpha: 0.95)),
        );
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(25, 20, 50, 10), const Radius.circular(5)), _fill(const Color(0xFF9AA4C8)));
        canvas.drawLine(const Offset(36, 38), const Offset(40, 80), _stroke(Colors.white, 4));
      case WasteKind.jar:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(34, 12, 32, 12), const Radius.circular(4)), _fill(const Color(0xFFC0A05E)));
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(28, 24, 44, 64), const Radius.circular(10)),
          _fill(const Color(0xFFA9DBC6).withValues(alpha: 0.85)),
        );
        canvas.drawLine(const Offset(37, 36), const Offset(37, 78), _stroke(Colors.white.withValues(alpha: 0.8), 5));
      case WasteKind.glassBottle:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(43, 8, 14, 10), const Radius.circular(3)), _fill(const Color(0xFF8A6B3F)));
        canvas.drawPath(
          Path()
            ..moveTo(44, 18)
            ..lineTo(44, 34)
            ..cubicTo(34, 42, 32, 48, 32, 58)
            ..lineTo(32, 84)
            ..cubicTo(32, 89, 36, 91, 50, 91)
            ..cubicTo(64, 91, 68, 89, 68, 84)
            ..lineTo(68, 58)
            ..cubicTo(68, 48, 66, 42, 56, 34)
            ..lineTo(56, 18)
            ..close(),
          _fill(const Color(0xFF6FAE7E).withValues(alpha: 0.9)),
        );
        canvas.drawLine(const Offset(39, 48), const Offset(39, 82), _stroke(Colors.white.withValues(alpha: 0.6), 4));
      case WasteKind.glassCup:
        canvas.drawPath(
          Path()
            ..moveTo(30, 22)
            ..lineTo(38, 70)
            ..lineTo(62, 70)
            ..lineTo(70, 22)
            ..close(),
          _fill(const Color(0xFFA9DBC6).withValues(alpha: 0.8)),
        );
        canvas.drawRect(const Rect.fromLTWH(46, 70, 8, 16), _fill(const Color(0xFFA9DBC6).withValues(alpha: 0.8)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(32, 84, 36, 8), const Radius.circular(4)), _fill(const Color(0xFFA9DBC6).withValues(alpha: 0.9)));
        canvas.drawLine(const Offset(38, 32), const Offset(42, 64), _stroke(Colors.white.withValues(alpha: 0.75), 4));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WastePainter old) => old.kind != kind;
}

/// A recycling bin with an open lid, drawn in its category colour.
class BinArt extends StatelessWidget {
  final WasteBin bin;
  final double size;
  final bool highlighted;
  const BinArt({super.key, required this.bin, this.size = 72, this.highlighted = false});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size * 0.9), painter: _BinPainter(bin, highlighted));
}

class _BinPainter extends CustomPainter {
  final WasteBin bin;
  final bool highlighted;
  _BinPainter(this.bin, this.highlighted);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 90);
    final c = bin.color;
    final dark = Color.lerp(c, Colors.black, 0.28)!;

    final body = Path()
      ..moveTo(20, 30)
      ..lineTo(27, 86)
      ..cubicTo(27, 89, 30, 90, 50, 90)
      ..cubicTo(70, 90, 73, 89, 73, 86)
      ..lineTo(80, 30)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..isAntiAlias = true
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(c, Colors.white, 0.25)!, dark],
        ).createShader(const Rect.fromLTWH(20, 30, 60, 60)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(14, 18, 72, 14), const Radius.circular(7)),
      Paint()..color = dark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(42, 8, 16, 10), const Radius.circular(4)),
      Paint()..color = dark,
    );
    for (final x in [36.0, 50.0, 64.0]) {
      canvas.drawLine(
        Offset(x, 44),
        Offset(x - 2, 78),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
    if (highlighted) {
      canvas.drawPath(
        body,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BinPainter old) => old.bin != bin || old.highlighted != highlighted;
}
