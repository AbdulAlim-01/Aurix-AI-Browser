import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'app_constant.dart';
import 'history_model.dart';
import 'local_history_service.dart';
import 'tab_model.dart';
import 'web_view_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<HistoryModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = LocalHistoryService.fetchHistory();
    });
  }

  Future<void> _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All History?'),
        content: const Text('Are you sure you want to delete all your browsing history? This action cannot be undone.'),
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
        await LocalHistoryService.clearAllHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All history has been deleted.')));
          _refreshHistory();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to clear history.')));
        }
      }
    }
  }

  Future<void> _deleteHistoryItem(String historyId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History Item?'),
        content: Text('Are you sure you want to delete the history item for "$title"?'),
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
        await LocalHistoryService.deleteHistoryItem(historyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History item deleted.')));
          _refreshHistory();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete item.')));
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
            // Don't need to do anything here for history browsing
          },
          onNewTabRequested: (url) {
            // Not implemented for history page
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
        title: Text('History', style: GoogleFonts.poppins()),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Delete All History',
            onPressed: _clearAllHistory,
          ),
        ],
      ),
      body: FutureBuilder<List<HistoryModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList();
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load history.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                leading: CachedNetworkImage(
                  imageUrl:
                      'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(item.url).host}',
                  width: 24,
                  height: 24,
                  placeholder: (context, url) =>
                      const Icon(Icons.public, size: 24),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.public, size: 24),
                ),
                title: Text(item.title ?? item.url),
                subtitle: Text(item.url,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _navigateToWebView(item.url),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppConstant.ERROR_COLOR),
                  tooltip: 'Delete History Item',
                  onPressed: () => _deleteHistoryItem(item.id, item.title ?? item.url),
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
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: AppConstant.PADDING_MEDIUM),
          Text(
            'No history yet',
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppConstant.PADDING_SMALL),
          Text(
            'Your browsing history will appear here.',
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
