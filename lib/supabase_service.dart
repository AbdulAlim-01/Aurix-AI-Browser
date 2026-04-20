import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_profile_model.dart';
import 'bookmark_model.dart';
import 'download_model.dart';

// Note: History is now handled locally via LocalHistoryService

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get authenticated user
  static User? get currentUser => _client.auth.currentUser;
  static String? get currentUserId => _client.auth.currentUser?.id;
  static bool get isAuthenticated => _client.auth.currentUser != null;

  // ═══════════════════════════════════════════════════════════
  // 🔐 AUTHENTICATION METHODS
  // ═══════════════════════════════════════════════════════════
  
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🧹 GENERAL DATA MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  static Future<void> clearAllUserData() async {
    if (!isAuthenticated) return;
    try {
      // Use Future.wait to run deletions in parallel
      await Future.wait([
        clearAllBookmarks(),
        // clearAllHistory(), // Handled locally now
        clearAllDownloads(),
      ]);
    } catch (e) {
      throw Exception('Failed to clear user data: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📖 BOOKMARKS
  // ═══════════════════════════════════════════════════════════

  static Future<void> addBookmark({required String url, String? title}) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    try {
      final faviconUrl = 'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(url).host}';
      await _client.from('bookmarks').insert({
        'user_id': currentUserId,
        'url': url,
        'title': title,
        'favicon_url': faviconUrl,
      });
    } catch (e) {
      throw Exception('Failed to add bookmark: $e');
    }
  }

  static Future<List<BookmarkModel>> fetchBookmarks() async {
    if (!isAuthenticated) return [];
    try {
      final response = await _client
          .from('bookmarks')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);
      return response.map((item) => BookmarkModel.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch bookmarks: $e');
    }
  }

  static Future<void> deleteBookmark(String bookmarkId) async {
    if (!isAuthenticated) return;
    try {
      await _client.from('bookmarks').delete().eq('id', bookmarkId);
    } catch (e) {
      throw Exception('Failed to delete bookmark: $e');
    }
  }
  
  static Future<void> clearAllBookmarks() async {
    if (!isAuthenticated) return;
    try {
      await _client.from('bookmarks').delete().eq('user_id', currentUserId!);
    } catch (e) {
      throw Exception('Failed to clear bookmarks: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📥 DOWNLOADS
  // ═══════════════════════════════════════════════════════════

  static Future<String?> addDownloadRecord({
    required String url,
    required String filename,
    String status = 'downloading',
  }) async {
    if (!isAuthenticated) return null;
    try {
      final response = await _client
          .from('downloads')
          .insert({
            'user_id': currentUserId,
            'url': url,
            'filename': filename,
            'status': status,
          })
          .select('id')
          .single();
      return response['id'];
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateDownloadRecord({
    required String recordId,
    required String status,
    String? filePath,
  }) async {
    if (!isAuthenticated) return;
    try {
      await _client
          .from('downloads')
          .update({
            'status': status,
            'file_path': filePath,
          })
          .eq('id', recordId);
    } catch (e) {
      // Fail silently
    }
  }

  static Future<List<DownloadModel>> fetchDownloads() async {
    if (!isAuthenticated) return [];
    try {
      final response = await _client
          .from('downloads')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);
      return response.map((item) => DownloadModel.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch downloads: $e');
    }
  }

  static Future<void> clearAllDownloads() async {
    if (!isAuthenticated) return;
    try {
      await _client.from('downloads').delete().eq('user_id', currentUserId!);
    } catch (e) {
      throw Exception('Failed to clear downloads: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🤖 AI CONTENT PROFILES
  // ═══════════════════════════════════════════════════════════

  static Future<List<AiProfile>> getAiProfiles() async {
    if (!isAuthenticated) return [];
    try {
      final response = await _client
          .from('ai_profiles')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: true);
      return response.map((item) => AiProfile.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch AI profiles: $e');
    }
  }

  static Future<void> createAiProfile(AiProfile profile) async {
    if (!isAuthenticated) return;
    try {
      await _client.from('ai_profiles').insert(profile.toMap());
    } catch (e) {
      throw Exception('Failed to create AI profile: $e');
    }
  }

  static Future<void> updateAiProfile(AiProfile profile) async {
    if (!isAuthenticated) return;
    try {
      await _client.from('ai_profiles').update(profile.toMap()).eq('id', profile.id!);
    } catch (e) {
      throw Exception('Failed to update AI profile: $e');
    }
  }

  static Future<void> deleteAiProfile(String profileId) async {
    if (!isAuthenticated) return;
    try {
      await _client.from('ai_profiles').delete().eq('id', profileId);
    } catch (e) {
      throw Exception('Failed to delete AI profile: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📊 ANALYTICS
  // ═══════════════════════════════════════════════════════════

  static Future<void> trackSearch() async {
    // Analytics are now anonymous and not tied to user authentication directly
    try {
      await _client.rpc('increment_daily_metric', params: {'p_action_type': 'search'});
    } catch (e) {
      // Fail silently
    }
  }

  static Future<void> trackSummary() async {
    try {
      await _client.rpc('increment_daily_metric', params: {'p_action_type': 'summary'});
    } catch (e) {
      // Fail silently
    }
  }

  static Future<void> trackChat() async {
    try {
      await _client.rpc('increment_daily_metric', params: {'p_action_type': 'chat'});
    } catch (e) {
      // Fail silently
    }
  }

  static Future<void> trackContentGeneration() async {
    try {
      await _client.rpc('increment_daily_metric', params: {'p_action_type': 'content'});
    } catch (e) {
      // Fail silently
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 💰 SUBSCRIPTION / PAID STATUS
  // ═══════════════════════════════════════════════════════════

  static Future<bool> isPaidUser() async {
    // For now, always return false (Free Plan only)
    return false;
    
    /* 
    // Paid plan logic commented out for future use
    if (!isAuthenticated) return false;
    try {
      // Check the 'profiles' table for the 'plan' column
      final response = await _client
          .from('profiles')
          .select('plan')
          .eq('id', currentUserId!)
          .maybeSingle();
      
      if (response != null && response['plan'] == 'paid') {
        return true;
      }
      return false;
    } catch (e) {
      return false; // Default to free on error
    }
    */
  }
}
