import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette mirrors the oklch tokens used in the design mockups
/// (design/*.dc.html) as closely as plain sRGB hex allows.
class WiamColors {
  // Child app: calm, warm night-sky theme.
  static const bg1 = Color(0xFF1B2140);
  static const bg2 = Color(0xFF12162A);
  static const card = Color(0xFF2A3155);
  static const cardLine = Color(0xFF3E4570);
  static const ink = Color(0xFFF6F3EC);
  static const inkMuted = Color(0xFFB9BEDD);
  static const amber = Color(0xFFE8B65B);
  static const amberDeep = Color(0xFFC98A3B);
  static const teal = Color(0xFF6FC2C4);
  static const planetDim = Color(0xFF5A6088);

  // Parent app: warm daytime theme.
  static const bgLight = Color(0xFFF7F4EE);
  static const cardLight = Color(0xFFFFFFFE);
  static const lineLight = Color(0xFFE7E1D3);
  static const inkLight = Color(0xFF32354A);
  static const inkMutedLight = Color(0xFF71748C);
  static const amberLight = Color(0xFFE3B95E);
  static const amberDeepLight = Color(0xFFAD7A2E);
  static const tealLight = Color(0xFF5FA8AA);
  static const tealDeepLight = Color(0xFF357376);
  static const tealTintLight = Color(0xFFE3F3F1);
  static const coral = Color(0xFFDD7259);
  static const coralDeep = Color(0xFFB24E38);
}

TextStyle displayFont({double? fontSize, FontWeight? fontWeight, Color? color, double? height}) =>
    GoogleFonts.balooBhaijaan2(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);

TextStyle bodyFont({double? fontSize, FontWeight? fontWeight, Color? color, double? height}) =>
    GoogleFonts.tajawal(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);

ThemeData wiamLightTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: WiamColors.bgLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: WiamColors.tealDeepLight,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.tajawalTextTheme(),
  );
}
