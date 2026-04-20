import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'app_constant.dart';
import 'bookmark_model.dart';
import 'supabase_service.dart';
import 'tab_model.dart';
import 'web_view_page.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  late Future<List<BookmarkModel>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _refreshBookmarks();
  }

  void _refreshBookmarks() {
    setState(() {
      _bookmarksFuture = SupabaseService.fetchBookmarks();
    });
  }

  Future<void> _deleteBookmark(String bookmarkId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark?'),
        content: Text('Are you sure you want to delete the bookmark for "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppConstant.ERROR_COLOR)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.deleteBookmark(bookmarkId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmark deleted.')));
          _refreshBookmarks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting bookmark: $e')));
        }
      }
    }
  }

  Future<void> _clearAllBookmarks() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Bookmarks?'),
        content: const Text('Are you sure you want to delete all your bookmarks? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: AppConstant.ERROR_COLOR)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.clearAllBookmarks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All bookmarks have been deleted.')));
          _refreshBookmarks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing bookmarks: $e')));
        }
      }
    }
  }

  void _navigateToWebView(String url) {
    final newTab = TabModel(id: DateTime.now().millisecondsSinceEpoch, url: url);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebViewPage(
          tabId: newTab.id,
          initialUrl: url,
          onTabUpdated: (tabId, newUrl, newTitle, newContent) {
            // Can update bookmark URL if needed, but for now just browse
          },
          onNewTabRequested: (url) {
            // Not implemented for bookmarks page
          },
          tabs: [newTab],
          activeTabIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarks', style: GoogleFonts.poppins()),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Delete All Bookmarks',
            onPressed: _clearAllBookmarks,
          ),
        ],
      ),
      body: FutureBuilder<List<BookmarkModel>>(
        future: _bookmarksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final bookmarks = snapshot.data!;
          return ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              return ListTile(
                leading: CachedNetworkImage(
                  imageUrl: bookmark.faviconUrl ??
                      'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(bookmark.url).host}',
                  width: 24,
                  height: 24,
                  placeholder: (context, url) =>
                      const Icon(Icons.public, size: 24),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.public, size: 24),
                ),
                title: Text(bookmark.title ?? bookmark.url),
                subtitle: Text(bookmark.url,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _navigateToWebView(bookmark.url),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppConstant.ERROR_COLOR),
                  onPressed: () => _deleteBookmark(bookmark.id, bookmark.title ?? bookmark.url),
                  tooltip: 'Delete Bookmark',
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: AppConstant.PADDING_MEDIUM),
          Text(
            'No bookmarks yet',
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppConstant.PADDING_SMALL),
          Text(
            'Tap the bookmark icon on a page to save it.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.white),
            title: Container(
              height: 16,
              width: 150,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 12,
              width: 200,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}
