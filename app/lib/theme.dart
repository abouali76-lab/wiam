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

  /// A slightly deeper wash used behind hero areas, so the page has two
  /// levels of ground rather than one flat colour.
  static const bgLightAlt = Color(0xFFF1ECE1);
  static const cardLight = Color(0xFFFFFDFA);
  static const lineLight = Color(0xFFE7E1D3);
  static const inkLight = Color(0xFF2E3142);
  static const inkMutedLight = Color(0xFF71748C);

  /// For captions and meta text that must stay quiet next to inkMutedLight.
  static const inkFaintLight = Color(0xFF9B9DAF);
  static const amberLight = Color(0xFFE3B95E);
  static const amberDeepLight = Color(0xFFAD7A2E);
  static const amberTintLight = Color(0xFFFBF2DF);
  static const tealLight = Color(0xFF5FA8AA);
  static const tealDeepLight = Color(0xFF357376);
  static const tealTintLight = Color(0xFFE3F3F1);
  static const coral = Color(0xFFDD7259);
  static const coralDeep = Color(0xFFB24E38);
  static const coralTintLight = Color(0xFFFBEAE4);
}

/// Two shadow levels only — a surface either sits on the page or lifts off
/// it. More levels than that just read as inconsistency.
class WiamShadow {
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x0D2A2318), blurRadius: 14, offset: Offset(0, 3)),
  ];
  static const lifted = <BoxShadow>[
    BoxShadow(color: Color(0x142A2318), blurRadius: 28, offset: Offset(0, 10)),
  ];
}

/// Corner radii, named by the size of thing they wrap.
class WiamRadius {
  static const chip = 999.0;
  static const control = 16.0;
  static const card = 22.0;
  static const sheet = 28.0;
}

TextStyle displayFont({double? fontSize, FontWeight? fontWeight, Color? color, double? height, double? letterSpacing}) =>
    GoogleFonts.balooBhaijaan2(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle bodyFont({double? fontSize, FontWeight? fontWeight, Color? color, double? height, double? letterSpacing}) =>
    GoogleFonts.tajawal(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

/// Named steps in the type scale, so screens stop inventing one-off sizes.
class WiamText {
  static TextStyle get hero =>
      displayFont(fontSize: 34, fontWeight: FontWeight.w800, color: WiamColors.inkLight, height: 1.2);
  static TextStyle get title =>
      displayFont(fontSize: 22, fontWeight: FontWeight.w700, color: WiamColors.inkLight, height: 1.25);
  static TextStyle get section =>
      bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMutedLight, letterSpacing: 0.4);
  static TextStyle get cardTitle =>
      bodyFont(fontSize: 15.5, fontWeight: FontWeight.w700, color: WiamColors.inkLight);
  static TextStyle get body =>
      bodyFont(fontSize: 14, color: WiamColors.inkMutedLight, height: 1.6);
  static TextStyle get caption =>
      bodyFont(fontSize: 12, color: WiamColors.inkFaintLight);
}

ThemeData wiamLightTheme() {
  final base = ColorScheme.fromSeed(seedColor: WiamColors.tealDeepLight, brightness: Brightness.light);
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: WiamColors.bgLight,
    colorScheme: base.copyWith(
      primary: WiamColors.tealDeepLight,
      surface: WiamColors.cardLight,
      error: WiamColors.coralDeep,
    ),
    textTheme: GoogleFonts.tajawalTextTheme(),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: WiamColors.bgLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: WiamColors.inkLight,
      titleTextStyle: displayFont(fontSize: 20, fontWeight: FontWeight.w700, color: WiamColors.inkLight),
    ),
    // A single input style everywhere: filled, borderless until focused.
    // Outlined boxes made the auth screens read like a tax form.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WiamColors.cardLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: bodyFont(fontSize: 14, color: WiamColors.inkFaintLight),
      labelStyle: bodyFont(fontSize: 14, color: WiamColors.inkMutedLight),
      floatingLabelStyle: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.tealDeepLight),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WiamRadius.control),
        borderSide: const BorderSide(color: WiamColors.lineLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WiamRadius.control),
        borderSide: const BorderSide(color: WiamColors.tealDeepLight, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WiamRadius.control),
        borderSide: const BorderSide(color: WiamColors.coralDeep),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WiamRadius.control),
        borderSide: const BorderSide(color: WiamColors.coralDeep, width: 1.8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: WiamColors.tealDeepLight,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WiamRadius.control)),
        textStyle: bodyFont(fontSize: 15.5, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: WiamColors.tealDeepLight,
        textStyle: bodyFont(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: WiamColors.cardLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WiamRadius.sheet)),
      titleTextStyle: displayFont(fontSize: 19, fontWeight: FontWeight.w700, color: WiamColors.inkLight),
      contentTextStyle: bodyFont(fontSize: 14, color: WiamColors.inkMutedLight, height: 1.6),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: WiamColors.inkLight,
      contentTextStyle: bodyFont(fontSize: 14, color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WiamRadius.control)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: WiamColors.bgLightAlt,
      side: const BorderSide(color: WiamColors.lineLight),
      labelStyle: bodyFont(fontSize: 12.5, color: WiamColors.inkLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WiamRadius.chip)),
    ),
    dividerTheme: const DividerThemeData(color: WiamColors.lineLight, thickness: 1, space: 1),
  );
}

/// The standard page surface: a soft card that sits on the warm background.
class WiamCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool lifted;
  final VoidCallback? onTap;
  const WiamCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.lifted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? WiamColors.cardLight,
        borderRadius: BorderRadius.circular(WiamRadius.card),
        border: Border.all(color: WiamColors.lineLight),
        boxShadow: lifted ? WiamShadow.lifted : WiamShadow.soft,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(WiamRadius.card),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// A small status pill — used for pairing state, freeze state and task state,
/// so all three read as the same kind of information.
class WiamPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool solid;
  const WiamPill({super.key, required this.label, this.icon, required this.color, this.solid = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon == null ? 12 : 10, vertical: 6),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(WiamRadius.chip),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: solid ? Colors.white : color),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: bodyFont(fontSize: 12, fontWeight: FontWeight.w700, color: solid ? Colors.white : color),
        ),
      ]),
    );
  }
}
