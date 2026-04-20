import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_constant.dart';
import 'supabase_service.dart';
import 'web_view_page.dart';
import 'tabs_page.dart';
import 'tab_model.dart';
import 'glassmorphic_container.dart';
import 'main_menu_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<TabModel> _tabs = [
    TabModel(id: DateTime.now().millisecondsSinceEpoch, url: 'https://google.com', title: 'Google'),
  ];
  int _activeTabIndex = 0;

  void _openNewTab({String? url, bool isIncognito = false}) {
    final newTab = TabModel(
      id: DateTime.now().millisecondsSinceEpoch,
      url: url ?? 'https://google.com',
      isIncognito: isIncognito,
    );
    setState(() {
      _tabs.add(newTab);
      _activeTabIndex = _tabs.length - 1;
    });
    _navigateToWebView(_tabs.length - 1);
  }

  void _navigateToWebView(int tabIndex) async {
    if (tabIndex < 0 || tabIndex >= _tabs.length) {
      if (_tabs.isEmpty) _openNewTab();
      return;
    }

    final currentTab = _tabs[tabIndex];
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebViewPage(
          key: ValueKey(currentTab.id),
          tabId: currentTab.id,
          initialUrl: currentTab.url,
          isIncognito: currentTab.isIncognito,
          tabs: _tabs,
          activeTabIndex: tabIndex,
          onNewTabRequested: (url) => _openNewTab(url: url.toString()),
          onTabUpdated: (tabId, newUrl, newTitle, newContent) {
            final index = _tabs.indexWhere((t) => t.id == tabId);
            if (index != -1) {
                if(mounted) {
                  setState(() {
                      _tabs[index].url = newUrl;
                      if (newTitle != null) _tabs[index].title = newTitle;
                      if (newContent != null) _tabs[index].content = newContent;
                  });
                }
            }
          },
        ),
      ),
    );

    _handleTabsResult(result);
  }

  void _showTabsPage() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TabsPage(
          tabs: _tabs,
          activeTabIndex: _activeTabIndex,
          onTabSelected: (index) {
            Navigator.pop(context, {'action': 'select', 'index': index});
          },
          onCloseTab: (index) {
            setState(() {
              _tabs.removeAt(index);
              if (_activeTabIndex >= index && _activeTabIndex > 0) {
                _activeTabIndex--;
              }
            });
          },
          onNewTab: () {
            Navigator.pop(context, {'action': 'new'});
          },
        ),
      ),
    );

    _handleTabsResult(result);
  }
  
  void _handleTabsResult(dynamic result) {
    if (result is! Map) {
      if (_tabs.isEmpty) {
        setState(() {
          _tabs.add(TabModel(id: DateTime.now().millisecondsSinceEpoch, url: 'https://google.com'));
          _activeTabIndex = 0;
        });
      }
      return;
    }

    switch (result['action']) {
      case 'select':
        final newIndex = result['index'];
        if (newIndex >= 0 && newIndex < _tabs.length) {
          setState(() => _activeTabIndex = newIndex);
          _navigateToWebView(newIndex);
        } else if (_tabs.isNotEmpty) {
           setState(() => _activeTabIndex = 0);
           _navigateToWebView(0);
        } else {
           _openNewTab();
        }
        break;
      case 'new':
        _openNewTab();
        break;
    }
  }

  void _showMainMenu() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const MainMenuBottomSheet(),
    );
     if (result == 'new_incognito') {
      _openNewTab(isIncognito: true);
    }
  }

  void _searchOrNavigate() {
    String input = _searchController.text.trim();
    if (input.isEmpty) return;

    bool isUrl = RegExp(r'^(http:\/\/|https:\/\/)?(www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(\/.*)?$').hasMatch(input);

    String finalUrl;
    if (isUrl) {
      finalUrl = (input.startsWith('http://') || input.startsWith('https://'))
          ? input
          : 'https://$input';
    } else {
      SupabaseService.trackSearch();
      finalUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(input)}';
    }
    
    _openNewTab(url: finalUrl);
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider("https://i.postimg.cc/65PgvG1V/bg1.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.2),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstant.PADDING_LARGE),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Browse Beyond",
                            style: GoogleFonts.poppins( // Using Poppins as a stand-in for Satoshi
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: Colors.white60,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSearchBar(),
                          const SizedBox(height: 24),
                          _buildCrazzyCard(),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                        tooltip: 'Main Menu',
                        onPressed: _showMainMenu,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTabsPage,
        backgroundColor: AppConstant.PRIMARY_COLOR.withOpacity(0.8),
        icon: const Icon(Icons.filter_none, color: Colors.white),
        label: Text('${_tabs.length}', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GlassmorphicContainer(
      blur: 15,
      borderRadius: BorderRadius.circular(50),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search or enter URL',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.9),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18.0,
            horizontal: AppConstant.PADDING_SMALL,
          ),
        ),
        onSubmitted: (_) => _searchOrNavigate(),
      ),
    );
  }

  Widget _buildCrazzyCard() {
    return GestureDetector(
      onTap: () => _openNewTab(url: 'https://crazzy.dev'),
      child: GlassmorphicContainer(
        blur: 15,
        borderRadius: BorderRadius.circular(AppConstant.BORDER_RADIUS_LARGE),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Text(
            'Turn your ideas into reality✨',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
