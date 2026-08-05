import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

/// Large, confident type scale in the spirit of Linear/Notion — few sizes,
/// generous line height, no more than two weights per screen. Display-scale
/// styles use Space Grotesk for geometric character at the moments that
/// matter (headlines, the dashboard's big ring number); body/caption text
/// stays on Inter, which already reads well at UI sizes.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get display => GoogleFonts.spaceGrotesk(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle get headline => GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
      );

  static TextStyle get title => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  static TextStyle get statNumber => GoogleFonts.spaceGrotesk(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.0,
      );
}
