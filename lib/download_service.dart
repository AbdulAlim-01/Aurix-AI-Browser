import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'download_model.dart';

class DownloadService {
  static const _downloadsKey = 'downloads';
  static const _uuid = Uuid();

  static Future<List<DownloadModel>> getDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadsJson = prefs.getStringList(_downloadsKey) ?? [];
    return downloadsJson.map((json) => DownloadModel.fromJson(json)).toList();
  }

  static Future<String> addDownload({
    required String url,
    required String filename,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final downloads = await getDownloads();
    final id = _uuid.v4();
    final newDownload = DownloadModel(
      id: id,
      url: url,
      filename: filename,
      status: 'downloading',
      createdAt: DateTime.now(),
    );
    downloads.add(newDownload);
    await _saveDownloads(prefs, downloads);
    return id;
  }

  static Future<void> updateDownloadStatus({
    required String id,
    required String status,
    String? filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final downloads = await getDownloads();
    final index = downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      final updatedDownload = DownloadModel(
        id: downloads[index].id,
        url: downloads[index].url,
        filename: downloads[index].filename,
        status: status,
        filePath: filePath ?? downloads[index].filePath,
        createdAt: downloads[index].createdAt,
      );
      downloads[index] = updatedDownload;
      await _saveDownloads(prefs, downloads);
    }
  }

  static Future<void> _saveDownloads(SharedPreferences prefs, List<DownloadModel> downloads) async {
    final downloadsJson = downloads.map((d) => d.toJson()).toList();
    await prefs.setStringList(_downloadsKey, downloadsJson);
  }
}
