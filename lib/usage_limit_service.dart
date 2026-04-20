import 'package:shared_preferences/shared_preferences.dart';

class UsageLimitService {
  static const String KEY_LAST_YOUTUBE_SUMMARY = 'last_youtube_summary';
  static const String KEY_LAST_ARTICLE_SUMMARY = 'last_article_summary';
  static const String KEY_LAST_CONTENT_GENERATION = 'last_content_generation';

  Future<bool> canPerformAction(String key, int cooldownMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTimeStr = prefs.getString(key);
    if (lastTimeStr == null) return true;

    final lastTime = DateTime.parse(lastTimeStr);
    final now = DateTime.now();
    final difference = now.difference(lastTime);
    
    return difference.inMinutes >= cooldownMinutes;
  }

  Future<Duration> getTimeUntilNextAction(String key, int cooldownMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTimeStr = prefs.getString(key);
    if (lastTimeStr == null) return Duration.zero;

    final lastTime = DateTime.parse(lastTimeStr);
    final now = DateTime.now();
    final difference = now.difference(lastTime);
    
    if (difference.inMinutes >= cooldownMinutes) return Duration.zero;
    
    return Duration(minutes: cooldownMinutes) - difference;
  }

  Future<void> markActionUsed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, DateTime.now().toIso8601String());
  }
}
