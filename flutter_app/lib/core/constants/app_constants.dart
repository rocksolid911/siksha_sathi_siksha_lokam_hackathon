/// App-wide constants for Shiksha Saathi
class AppConstants {
  AppConstants._();

  // ═══════════════════════════════════════════════════════════════════════════
  // APP INFO
  // ═══════════════════════════════════════════════════════════════════════════
  static const String appName = 'Shiksha Saathi';
  static const String appNameHindi = 'शिक्षा साथी';
  static const String tagline = 'Your AI Teaching Partner';
  static const String taglineHindi = 'आपका AI शिक्षण साथी';
  static const String version = '1.0.0';

  // ═══════════════════════════════════════════════════════════════════════════
  // API CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  static const String apiBaseUrl = 'http://192.168.1.33:8000/api/v1';
  static const Duration apiTimeout = Duration(seconds: 90);

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING
  // ═══════════════════════════════════════════════════════════════════════════
  static const double spacingXxs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════════
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // ELEVATION
  // ═══════════════════════════════════════════════════════════════════════════
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // ICON SIZES
  // ═══════════════════════════════════════════════════════════════════════════
  static const double iconSizeSm = 16.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADES
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<String> grades = [
    'कक्षा 1',
    'कक्षा 2',
    'कक्षा 3',
    'कक्षा 4',
    'कक्षा 5',
    'कक्षा 6',
    'कक्षा 7',
    'कक्षा 8',
  ];

  static const List<String> gradesEnglish = [
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBJECTS
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<String> subjects = [
    'गणित',
    'हिंदी',
    'English',
    'विज्ञान',
    'सामाजिक विज्ञान',
  ];

  static const List<String> subjectsEnglish = [
    'Mathematics',
    'Hindi',
    'English',
    'Science',
    'Social Science',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME OPTIONS (for SOS)
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<int> timeOptions = [5, 10, 15];

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK SCENARIOS (for SOS)
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<Map<String, String>> quickScenarios = [
    {
      'icon': '😴',
      'title': 'Students disengaged',
      'titleHi': 'छात्र ध्यान नहीं दे रहे',
    },
    {
      'icon': '🤷',
      'title': 'Concept not clicking',
      'titleHi': 'समझ नहीं आ रहा',
    },
    {
      'icon': '🎪',
      'title': 'Activity not working',
      'titleHi': 'गतिविधि काम नहीं कर रही',
    },
    {
      'icon': '🔊',
      'title': 'Classroom chaos',
      'titleHi': 'कक्षा में अव्यवस्था',
    },
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // CHALLENGE CATEGORIES
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<Map<String, String>> challengeCategories = [
    {
      'icon': '😴',
      'title': 'Students not engaging',
      'titleHi': 'छात्र भाग नहीं ले रहे',
    },
    {
      'icon': '🤷',
      'title': 'Concept not clicking',
      'titleHi': 'अवधारणा समझ नहीं आ रही',
    },
    {
      'icon': '⏰',
      'title': 'Time running out',
      'titleHi': 'समय कम है',
    },
    {
      'icon': '🎭',
      'title': 'Mixed-ability class',
      'titleHi': 'मिश्रित क्षमता वाली कक्षा',
    },
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBJECT ICON & COLOR CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get subject-specific icon and colors
  /// Returns a map with 'icon', 'iconBgColor', and 'iconColor'
  static Map<String, dynamic> getSubjectConfig(String? subject) {
    final subjectLower = (subject ?? '').toLowerCase();

    // Math
    if (subjectLower.contains('math') || subjectLower.contains('गणित')) {
      return {
        'icon': 'calculate_outlined',
        'iconBgColor': 0xFFE8F5E9, // Light green
        'iconColor': 0xFF4CAF50, // Green
      };
    }

    // Science
    if (subjectLower.contains('science') || subjectLower.contains('विज्ञान')) {
      return {
        'icon': 'science_outlined',
        'iconBgColor': 0xFFE3F2FD, // Light blue
        'iconColor': 0xFF2196F3, // Blue
      };
    }

    // English
    if (subjectLower.contains('english')) {
      return {
        'icon': 'menu_book_outlined',
        'iconBgColor': 0xFFFCE7F3, // Light pink
        'iconColor': 0xFFEC4899, // Pink
      };
    }

    // Hindi
    if (subjectLower.contains('hindi') || subjectLower.contains('हिंदी')) {
      return {
        'icon': 'translate_outlined',
        'iconBgColor': 0xFFFEF3C7, // Light yellow
        'iconColor': 0xFFF59E0B, // Amber
      };
    }

    // Social Science/Studies
    if (subjectLower.contains('social') || subjectLower.contains('सामाजिक')) {
      return {
        'icon': 'public_outlined',
        'iconBgColor': 0xFFDDD6FE, // Light purple
        'iconColor': 0xFF8B5CF6, // Purple
      };
    }

    // Computer Science
    if (subjectLower.contains('computer') || subjectLower.contains('cs')) {
      return {
        'icon': 'computer_outlined',
        'iconBgColor': 0xFFE0F2FE, // Light cyan
        'iconColor': 0xFF0EA5E9, // Cyan
      };
    }

    // Physical Education/Sports
    if (subjectLower.contains('physical') ||
        subjectLower.contains('pe') ||
        subjectLower.contains('sports')) {
      return {
        'icon': 'sports_outlined',
        'iconBgColor': 0xFFFEE2E2, // Light red
        'iconColor': 0xFFEF4444, // Red
      };
    }

    // Art/Drawing
    if (subjectLower.contains('art') || subjectLower.contains('drawing')) {
      return {
        'icon': 'palette_outlined',
        'iconBgColor': 0xFFFED7AA, // Light orange
        'iconColor': 0xFFF97316, // Orange
      };
    }

    // Music
    if (subjectLower.contains('music') || subjectLower.contains('संगीत')) {
      return {
        'icon': 'music_note_outlined',
        'iconBgColor': 0xFFE9D5FF, // Light violet
        'iconColor': 0xFFA855F7, // Violet
      };
    }

    // Default (for unknown subjects)
    return {
      'icon': 'lightbulb_outline_rounded',
      'iconBgColor': 0xFFFFF3E0, // Light orange
      'iconColor': 0xFFFF9800, // Orange
    };
  }
}
