import 'package:flutter/material.dart';
import 'ai_profile_page.dart';
import 'app_constant.dart';
import 'downloads_page.dart';
import 'glassmorphic_container.dart';
import 'settings_page.dart';
import 'supabase_service.dart';
import 'bookmarks_page.dart';
import 'history_page.dart';

class MainMenuBottomSheet extends StatelessWidget {
  const MainMenuBottomSheet({super.key});
  
  Future<void> _showClearDataDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will permanently delete all your bookmarks, history, and downloads. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Data', style: TextStyle(color: AppConstant.ERROR_COLOR)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.clearAllUserData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All browsing data cleared.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing data: $e'), backgroundColor: AppConstant.ERROR_COLOR));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      blur: 20,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppConstant.BORDER_RADIUS_XL),
        topRight: Radius.circular(AppConstant.BORDER_RADIUS_XL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstant.PADDING_MEDIUM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: AppConstant.PADDING_LARGE),
            _buildMenuItem(context, icon: Icons.bookmark, title: 'Bookmarks', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksPage()));
            }),
            _buildMenuItem(context, icon: Icons.history, title: 'History', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
            }),
            _buildMenuItem(context, icon: Icons.download, title: 'Downloads', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsPage()));
            }),
            const Divider(),
             _buildMenuItem(context, icon: Icons.psychology, title: 'AI Content Profile', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AiProfilePage()));
            }),
            _buildMenuItem(context, icon: Icons.security, title: 'New Incognito Tab', onTap: () {
              Navigator.pop(context, 'new_incognito');
            }),
            _buildMenuItem(context, icon: Icons.settings, title: 'Settings', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            }),
            _buildMenuItem(
              context, 
              icon: Icons.delete_sweep, 
              title: 'Clear Browsing Data', 
              color: AppConstant.ERROR_COLOR,
              onTap: () {
                Navigator.pop(context);
                _showClearDataDialog(context);
              }
            ),
             const Divider(),
            _buildMenuItem(
              context, 
              icon: Icons.logout, 
              title: 'Logout', 
              onTap: () async {
                Navigator.pop(context);
                await SupabaseService.signOut();
              }
            ),
            const SizedBox(height: AppConstant.PADDING_MEDIUM),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    final itemColor = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(title, style: TextStyle(color: itemColor)),
      onTap: onTap,
    );
  }
}
