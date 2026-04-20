import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shimmer/shimmer.dart';
import 'app_constant.dart';
import 'download_model.dart';
import 'supabase_service.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  late Future<List<DownloadModel>> _downloadsFuture;

  @override
  void initState() {
    super.initState();
    _refreshDownloads();
  }

  void _refreshDownloads() {
    setState(() {
      _downloadsFuture = SupabaseService.fetchDownloads();
    });
  }

  Future<void> _clearAllDownloads() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Downloads?'),
        content: const Text('This will clear your download history, but not the downloaded files on your device. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: AppConstant.ERROR_COLOR)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.clearAllDownloads();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download history cleared.')));
          _refreshDownloads();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing downloads: $e')));
        }
      }
    }
  }

  Future<void> _openFile(String? path) async {
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File path not available.')));
      return;
    }
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: ${result.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Downloads', style: GoogleFonts.poppins()),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All Downloads',
            onPressed: _clearAllDownloads,
          ),
        ],
      ),
      body: FutureBuilder<List<DownloadModel>>(
        future: _downloadsFuture,
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

          final downloads = snapshot.data!;
          return ListView.builder(
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              final download = downloads[index];
              return ListTile(
                leading: Icon(_getIconForStatus(download.status)),
                title: Text(download.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(download.status, style: TextStyle(color: _getColorForStatus(download.status))),
                onTap: download.status == 'completed' ? () => _openFile(download.filePath) : null,
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'downloading':
        return Icons.downloading;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'failed':
        return AppConstant.ERROR_COLOR;
      case 'downloading':
        return AppConstant.PRIMARY_COLOR;
      default:
        return AppConstant.TEXT_SECONDARY;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_done, size: 80, color: Colors.grey[400]),
          const SizedBox(height: AppConstant.PADDING_MEDIUM),
          Text(
            'No downloads yet',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppConstant.PADDING_SMALL),
          Text(
            'Your downloaded files will appear here.',
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