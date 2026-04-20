import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_model.dart';

class LocalHistoryService {
  static const String _storageKey = 'local_history_v1';

  static Future<void> addHistoryItem({required String url, String? title}) async {
    final prefs = await SharedPreferences.getInstance();
    List<HistoryModel> history = await fetchHistory();

    // Check if the last item is the same to avoid duplicates
    if (history.isNotEmpty && history.first.url == url) {
      return;
    }

    final newItem = HistoryModel(
      url: url,
      title: title,
      visitedAt: DateTime.now(),
    );

    history.insert(0, newItem);
    
    // Limit history size (e.g., 200 items)
    if (history.length > 200) {
      history = history.sublist(0, 200);
    }

    final String encoded = jsonEncode(history.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<List<HistoryModel>> fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_storageKey);
    
    if (historyString == null || historyString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(historyString);
      return decoded.map((e) => HistoryModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteHistoryItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<HistoryModel> history = await fetchHistory();
    
    history.removeWhere((item) => item.id == id);
    
    final String encoded = jsonEncode(history.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
