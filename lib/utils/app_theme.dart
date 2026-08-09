import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// PAIRRIDE DRIVER — DESIGN TOKENS
/// ──────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Primary palette — deep indigo / electric blue
  static const Color primary = Color(0xFF1A1A2E);
  static const Color primaryMid = Color(0xFF0F3460);
  static const Color primaryLight = Color(0xFF16537E);
  static const Color electricBlue = Color(0xFF0096FF);

  // Accent
  static const Color accent = Color(0xFFF5A623);
  static const Color accentLight = Color(0xFFFFD580);

  // Surfaces
  static const Color surfaceLight = Color(0xFFF4F6FA);
  static const Color surfaceDark = Color(0xFF0D1117);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF161B22);

  // Gradients
  static const Color gradientStart = Color(0xFF1A1A2E);
  static const Color gradientEnd = Color(0xFF0F3460);

  // Status
  static const Color success = Color(0xFF2ECC71);
  static const Color online = Color(0xFF00D26A);
  static const Color offline = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Service type colors
  static const Color singleRide = Color(0xFF0096FF);
  static const Color interstate = Color(0xFF6C5CE7);
  static const Color haulage = Color(0xFFE17055);
  static const Color dispatch = Color(0xFF00B894);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnDark = Color(0xFFF4F6FA);
  static const Color textOnPrimary = Colors.white;
}

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
  );

  static const LinearGradient dark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1117), Color(0xFF000000)],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accent, Color(0xFFFF8C00)],
  );

  static const LinearGradient splash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF0A0A1A)],
  );

  static const LinearGradient online = LinearGradient(
    colors: [Color(0xFF00D26A), Color(0xFF00B894)],
  );

  static LinearGradient serviceType(String type) {
    switch (type) {
      case 'interstate':
        return const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
        );
      case 'haulage':
        return const LinearGradient(
          colors: [Color(0xFFE17055), Color(0xFFD63031)],
        );
      case 'dispatch':
        return const LinearGradient(
          colors: [Color(0xFF00B894), Color(0xFF00897B)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF0096FF), Color(0xFF0077CC)],
        );
    }
  }
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Service type icon data
IconData serviceTypeIcon(String type) {
  switch (type) {
    case 'interstate':
      return Icons.route;
    case 'haulage':
      return Icons.local_shipping;
    case 'dispatch':
      return Icons.inventory_2;
    default:
      return Icons.directions_car;
  }
}

/// Service type display label
String serviceTypeLabel(String type) {
  switch (type) {
    case 'interstate':
      return 'Interstate';
    case 'haulage':
      return 'Haulage';
    case 'dispatch':
      return 'Dispatch';
    default:
      return 'Single Ride';
  }
}

/// Service type color
Color serviceTypeColor(String type) {
  switch (type) {
    case 'interstate':
      return AppColors.interstate;
    case 'haulage':
      return AppColors.haulage;
    case 'dispatch':
      return AppColors.dispatch;
    default:
      return AppColors.singleRide;
  }
}
