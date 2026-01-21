import 'package:flutter/material.dart';

/// Shiksha Saathi Color Palette
/// Designed for Indian education context - trust, calm, and action
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY - Trust & Calm (Education Green)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);
  static const Color primaryContainer = Color(0xFFB8E6B9);
  static const Color onPrimary = Colors.white;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECONDARY - Energy & Action (Vibrant Orange)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color secondary = Color(0xFFFF6F00);
  static const Color secondaryLight = Color(0xFFFF9E40);
  static const Color secondaryDark = Color(0xFFC43E00);
  static const Color secondaryContainer = Color(0xFFFFE0B2);
  static const Color onSecondary = Colors.white;
  static const Color accent = secondary; // Alias for backward compatibility

  // ═══════════════════════════════════════════════════════════════════════════
  // SOS - Urgency & Emergency (Alert Red)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color sos = Color(0xFFD32F2F);
  static const Color sosLight = Color(0xFFFFCDD2);
  static const Color sosDark = Color(0xFF9A0007);
  static const Color onSos = Colors.white;
  static const Color error = sos; // Alias for backward compatibility

  // ═══════════════════════════════════════════════════════════════════════════
  // SUCCESS - Positive Reinforcement
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color success = Color(0xFF388E3C);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color onSuccess = Colors.white;

  // ═══════════════════════════════════════════════════════════════════════════
  // WARNING
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color warning = Color(0xFFFFA000);
  static const Color warningLight = Color(0xFFFFECB3);
  static const Color onWarning = Colors.black;

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTRAL - Backgrounds & Text
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFEEEEEE);
  static const Color cardBackground = Colors.white;

  // NEUTRAL PALETTE
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnDark = Colors.white;

  // Border & Dividers
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkCardBackground = Color(0xFF252525);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sosGradient = LinearGradient(
    colors: [sos, Color(0xFFFF5252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primary, Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBJECT COLORS (For visual distinction)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color mathColor = Color(0xFF1976D2); // Blue
  static const Color hindiColor = Color(0xFFE65100); // Deep Orange
  static const Color englishColor = Color(0xFF7B1FA2); // Purple
  static const Color scienceColor = Color(0xFF00897B); // Teal
  static const Color socialColor = Color(0xFF5D4037); // Brown

  /// Get color for a subject
  static Color getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
      case 'गणित':
      case 'mathematics':
        return mathColor;
      case 'hindi':
      case 'हिंदी':
        return hindiColor;
      case 'english':
      case 'अंग्रेजी':
        return englishColor;
      case 'science':
      case 'विज्ञान':
        return scienceColor;
      case 'social':
      case 'सामाजिक':
      case 'social science':
        return socialColor;
      default:
        return primary;
    }
  }
}
