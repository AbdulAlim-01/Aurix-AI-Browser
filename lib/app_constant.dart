import 'package:flutter/material.dart';

class AppConstant {
  // ═══════════════════════════════════════════════════════════
  // 🎨 APP CONFIGURATION
  // ═══════════════════════════════════════════════════════════
  static const String APP_NAME = 'NovaBrowser';
  
  // Light Mode Colors
  static const Color PRIMARY_COLOR = Color(0xFFF3A3FF);
  static const Color SECONDARY_COLOR = Color(0xFF57C5B6); // Teal
  static const Color ACCENT_COLOR = Color(0xFFFFE15D); // Yellow
  static const Color BACKGROUND_COLOR_LIGHT = Color(0xFFF2F2F7);
  static const Color SURFACE_COLOR_LIGHT = Color(0xFFFFFFFF);
  static const Color TEXT_PRIMARY = Color(0xFF000000);
  static const Color TEXT_SECONDARY = Color(0xFF757575);

  // Dark Mode Colors
  static const Color BACKGROUND_COLOR_DARK = Color(0xFF1C1C1E);
  static const Color SURFACE_COLOR_DARK = Color(0xFF2C2C2E);
  static const Color TEXT_PRIMARY_DARK = Color(0xFFFFFFFF);
  static const Color TEXT_SECONDARY_DARK = Color(0xFF8E8E93);

  // Common Colors
  static const Color ERROR_COLOR = Color(0xFFB00020);
  static const Color INCOGNITO_COLOR = Color(0xFF3D3D3D);
  
  // ═══════════════════════════════════════════════════════════
  // 🗄️ SUPABASE CONFIGURATION
  // ═══════════════════════════════════════════════════════════
  static const String SUPABASE_URL = 'YOUR_SUPABASE_URL';
  static const String SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

  // ═══════════════════════════════════════════════════════════
  // 🤖 AI (GEMINI) CONFIGURATION
  // ═══════════════════════════════════════════════════════════
  static const String GEMINI_API_KEY = 'YOUR_GEMINI_API_KEY'; // <-- IMPORTANT: REPLACE THIS
  static const String GEMINI_TEXT_MODEL = 'gemini-2.5-flash-lite';
  static const String GEMINI_VIDEO_MODEL = 'gemini-2.5-flash-lite';
  static const String CROSS_TAB_CHAT_PROMPT = """
  You are a powerful research assistant AI. You have been given content from multiple web browser tabs. Your task is to analyze, compare, and synthesize the information from these tabs to answer the user's questions. 

  When answering, clearly reference which tab the information comes from if relevant (e.g., "According to the article on Tab 1..."). Be concise, accurate, and directly address the user's query.
  """;

  // ═══════════════════════════════════════════════════════════
  // 🌐 BROWSER CONFIGURATION
  // ═══════════════════════════════════════════════════════════
  static const List<String> SOCIAL_MEDIA_DOMAINS = [
    'linkedin.com',
    'x.com',
    'twitter.com',
    'reddit.com',
    'instagram.com',
    'dev.to',
    'facebook.com',
    'threads.net',
  ];
  
  static const List<String> SEARCH_ENGINE_DOMAINS = [
    'google.com',
    'bing.com',
    'duckduckgo.com',
    'yahoo.com',
  ];
  
  static const List<String> CODE_HOSTING_DOMAINS = [
    'github.com',
    'gitlab.com',
    'bitbucket.org',
  ];

  // ═══════════════════════════════════════════════════════════
  // 🎨 UI CONSTANTS
  // ═══════════════════════════════════════════════════════════
  static const double PADDING_SMALL = 8.0;
  static const double PADDING_MEDIUM = 16.0;
  static const double PADDING_LARGE = 24.0;
  static const double PADDING_XLARGE = 32.0;
  
  static const double BORDER_RADIUS_MEDIUM = 8.0;
  static const double BORDER_RADIUS_LARGE = 16.0;
  static const double BORDER_RADIUS_XL = 24.0;
  
  static const double ELEVATION = 4.0;

  // ═══════════════════════════════════════════════════════════
  // ⏱️ USAGE LIMITS
  // ═══════════════════════════════════════════════════════════
  // Free Tier
  static const int CHAT_MESSAGE_LIMIT = 15;
  static const int YOUTUBE_SUMMARY_COOLDOWN_MINUTES = 5;
  static const int ARTICLE_SUMMARY_COOLDOWN_MINUTES = 5;
  static const int GENERATE_CONTENT_COOLDOWN_MINUTES = 1;

  // Paid Tier
  static const int PAID_CHAT_MESSAGE_LIMIT = 30;
  static const int PAID_YOUTUBE_SUMMARY_COOLDOWN_MINUTES = 1;
  static const int PAID_ARTICLE_SUMMARY_COOLDOWN_MINUTES = 1;
  static const int PAID_GENERATE_CONTENT_COOLDOWN_MINUTES = 1;
}
