import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Institutional Palette
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy
  static const Color primaryLight = Color(0xFF3B82F6); // Blue Accent
  static const Color primaryDark = Color(0xFF172554); // Dark Navy

  // Secondary Accent
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color secondaryLight = Color(0xFF14B8A6);
  static const Color secondaryDark = Color(0xFF0F766E);

  // Neutral Backgrounds & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400

  // Neutral Backgrounds & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF0B1120); // Deep Dark Slate
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155); // Slate 700
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Workflow Status Colors
  static const Color statusPending = Color(0xFFD97706); // Amber 600
  static const Color statusPendingBg = Color(0xFFFEF3C7); // Amber 100
  static const Color statusInReview = Color(0xFF0284C7); // Sky 600
  static const Color statusInReviewBg = Color(0xFFE0F2FE); // Sky 100
  static const Color statusApproved = Color(0xFF059669); // Emerald 600
  static const Color statusApprovedBg = Color(0xFFD1FAE5); // Emerald 100
  static const Color statusRejected = Color(0xFFDC2626); // Red 600
  static const Color statusRejectedBg = Color(0xFFFEE2E2); // Red 100
  static const Color statusReturned = Color(0xFF7C3AED); // Purple 600
  static const Color statusReturnedBg = Color(0xFFEDE9FE); // Purple 100
  static const Color statusDraft = Color(0xFF475569); // Slate 600
  static const Color statusDraftBg = Color(0xFFF1F5F9); // Slate 100

  // Priority Colors
  static const Color priorityLow = Color(0xFF0284C7); // Sky
  static const Color priorityMedium = Color(0xFFD97706); // Amber
  static const Color priorityHigh = Color(0xFFEA580C); // Orange
  static const Color priorityUrgent = Color(0xFFDC2626); // Red
}
