import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.urbanist(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
      ),
      headlineLarge: GoogleFonts.urbanist(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
      ),
      headlineMedium: GoogleFonts.urbanist(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      ),
      titleLarge: GoogleFonts.urbanist(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
      ),
      bodyLarge: GoogleFonts.urbanist(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
      ),
      bodyMedium: GoogleFonts.urbanist(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      ),
      bodySmall: GoogleFonts.urbanist(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
      ),
      labelLarge: GoogleFonts.urbanist(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 20 / 16,
      ),
      labelMedium: GoogleFonts.urbanist(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 18 / 14,
      ),
      labelSmall: GoogleFonts.urbanist(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 14 / 11,
      ),
    );
  }

  static TextTheme get banglaTextTheme {
    // For Bangla, sizes are +1px, line height +4px, weight adjusted
    return TextTheme(
      displayLarge: GoogleFonts.hindSiliguri(
        fontSize: 33,
        fontWeight: FontWeight.w700,
        height: 44 / 33,
        letterSpacing: -0.2,
      ),
      headlineLarge: GoogleFonts.hindSiliguri(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        height: 36 / 25,
        letterSpacing: -0.2,
      ),
      headlineMedium: GoogleFonts.hindSiliguri(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 32 / 21,
        letterSpacing: -0.2,
      ),
      titleLarge: GoogleFonts.hindSiliguri(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 28 / 19,
        letterSpacing: -0.2,
      ),
      bodyLarge: GoogleFonts.hindSiliguri(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 28 / 17,
        letterSpacing: -0.2,
      ),
      bodyMedium: GoogleFonts.hindSiliguri(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 24 / 15,
        letterSpacing: -0.2,
      ),
      bodySmall: GoogleFonts.hindSiliguri(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 20 / 13,
        letterSpacing: -0.2,
      ),
      labelLarge: GoogleFonts.hindSiliguri(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 24 / 17,
        letterSpacing: -0.2,
      ),
      labelMedium: GoogleFonts.hindSiliguri(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 22 / 15,
        letterSpacing: -0.2,
      ),
      labelSmall: GoogleFonts.hindSiliguri(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 18 / 12,
        letterSpacing: -0.2,
      ),
    );
  }
}
