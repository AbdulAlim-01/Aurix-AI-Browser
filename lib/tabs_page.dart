import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_constant.dart';
import 'cross_tab_chat_page.dart';
import 'premium_limit_popup.dart';
import 'supabase_service.dart';
import 'tab_model.dart';
import 'usage_limit_service.dart';
import 'glassmorphic_container.dart';

class TabsPage extends StatefulWidget {
  final List<TabModel> tabs;
  final int activeTabIndex;
  final Function(int) onTabSelected;
  final Function(int) onCloseTab;
  final VoidCallback onNewTab;

  const TabsPage({
    super.key,
    required this.tabs,
    required this.activeTabIndex,
    required this.onTabSelected,
    required this.onCloseTab,
    required this.onNewTab,
  });

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  late List<TabModel> _localTabs;
  late int _localActiveTabIndex;
  final _usageLimitService = UsageLimitService();

  // State for multi-selection
  bool _isSelectionMode = false;
  Set<int> _selectedTabIds = {};

  @override
  void initState() {
    super.initState();
    _localTabs = List.from(widget.tabs);
    _localActiveTabIndex = widget.activeTabIndex;
  }

  void _handleCloseTab(int index) {
    final tabId = _localTabs[index].id;
    widget.onCloseTab(index);
    setState(() {
      _localTabs.removeAt(index);
      _selectedTabIds.remove(tabId);
      if (_localActiveTabIndex >= index && _localActiveTabIndex > 0) {
        _localActiveTabIndex--;
      }
      if(_localTabs.isEmpty) {
        _isSelectionMode = false;
        _selectedTabIds.clear();
      }
    });
  }
  
  void _toggleSelection(int tabId) {
    setState(() {
      if (_selectedTabIds.contains(tabId)) {
        _selectedTabIds.remove(tabId);
        if (_selectedTabIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        if (_selectedTabIds.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 4 tabs allowed.'))
          );
          return;
        }
        _selectedTabIds.add(tabId);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _startChatBetweenTabs() async {
    if (_selectedTabIds.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one tab.'))
      );
      return;
    }

    final isPaid = await SupabaseService.isPaidUser();
    final cooldown = isPaid ? AppConstant.PAID_ARTICLE_SUMMARY_COOLDOWN_MINUTES : AppConstant.ARTICLE_SUMMARY_COOLDOWN_MINUTES;
    const limitKey = UsageLimitService.KEY_LAST_ARTICLE_SUMMARY;

    if (!await _usageLimitService.canPerformAction(limitKey, cooldown)) {
      final remaining = await _usageLimitService.getTimeUntilNextAction(limitKey, cooldown);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => PremiumLimitPopup(
            waitTime: remaining,
            onSubscribe: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subscription coming soon!')),
              );
            },
            onWait: () => Navigator.pop(context),
          ),
        );
      }
      return;
    }
    
    final Map<String, String> selectedTabsContent = {};
    for (var tabId in _selectedTabIds) {
      final tab = _localTabs.firstWhere((t) => t.id == tabId, orElse: () => TabModel(id: -1, url: ''));
      if (tab.id != -1) {
        final title = tab.title ?? 'Untitled Tab';
        final content = tab.content;
        if (content != null && content.isNotEmpty) {
          selectedTabsContent[title] = content;
        }
      }
    }

    if (selectedTabsContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not extract text from selected tabs.'))
      );
      return;
    }
    
    await _usageLimitService.markActionUsed(limitKey);
    SupabaseService.trackChat();

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CrossTabChatPage(tabsContent: selectedTabsContent),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_isSelectionMode ? '${_selectedTabIds.length} Selected' : 'All Tabs', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancel Selection',
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedTabIds.clear();
              }),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Tab',
            onPressed: widget.onNewTab,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstant.PRIMARY_COLOR.withOpacity(0.6),
              Theme.of(context).colorScheme.background,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: _localTabs.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppConstant.PADDING_MEDIUM),
                      child: Text(
                        "Select tabs to chat",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstant.PADDING_MEDIUM),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppConstant.PADDING_MEDIUM,
                          mainAxisSpacing: AppConstant.PADDING_MEDIUM,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _localTabs.length,
                        itemBuilder: (context, index) {
                          return _buildTabCard(context, index);
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _buildChatInputField(),
    );
  }

  Widget _buildChatInputField() {
    return GlassmorphicContainer(
      blur: 20,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppConstant.PADDING_SMALL),
        child: SafeArea(
          child: GestureDetector(
            onTap: _startChatBetweenTabs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppConstant.BORDER_RADIUS_XL),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chat between tabs...',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  ),
                  Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabCard(BuildContext context, int index) {
    final tab = _localTabs[index];
    final isActive = index == _localActiveTabIndex && !_isSelectionMode;
    final isSelected = _selectedTabIds.contains(tab.id);
    
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(tab.id);
        } else {
          widget.onTabSelected(index);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
           _toggleSelection(tab.id);
        }
      },
      child: GlassmorphicContainer(
        borderRadius: BorderRadius.circular(AppConstant.BORDER_RADIUS_LARGE),
        blur: 15,
        color: tab.isIncognito ? AppConstant.INCOGNITO_COLOR.withOpacity(0.4) 
               : isSelected ? AppConstant.PRIMARY_COLOR.withOpacity(0.3)
               : null,
        borderColor: isActive ? AppConstant.PRIMARY_COLOR : (isSelected ? AppConstant.PRIMARY_COLOR.withOpacity(0.8) : Colors.transparent),
        borderWidth: 2,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstant.PADDING_SMALL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppConstant.BORDER_RADIUS_MEDIUM),
                      ),
                      child: Center(child: Icon(Icons.public, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    ),
                  ),
                  const SizedBox(height: AppConstant.PADDING_SMALL),
                  Text(
                    tab.title ?? tab.url,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (tab.isIncognito) const Icon(Icons.security, size: 14),
                      if (tab.isIncognito) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tab.url,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _handleCloseTab(index),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                left: 8,
                child: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 24),
              ),
          ],
        ),
      ),
    );
  }
   Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tab_unselected, size: 80, color: Colors.grey[400]),
          const SizedBox(height: AppConstant.PADDING_MEDIUM),
          Text(
            'No tabs open',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppConstant.PADDING_SMALL),
          Text(
            'Tap the \'+\' to start browsing.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
