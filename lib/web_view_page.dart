// web_view_page.dart
import 'dart:async'; // Add this import for Timer
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_chat_page.dart';
import 'app_constant.dart';
import 'glassmorphic_container.dart';
import 'social_content_generator_sheet.dart';
import 'usage_limit_service.dart';
import 'download_service.dart';
import 'supabase_service.dart';
import 'local_history_service.dart';
import 'premium_limit_popup.dart';
import 'tab_model.dart';
import 'tabs_page.dart';

class WebViewPage extends StatefulWidget {
  final int tabId;
  final String initialUrl;
  final Function(int tabId, String newUrl, String? newTitle, String? newContent)
      onTabUpdated;
  final Function(Uri url) onNewTabRequested;
  final bool isIncognito;
  final List<TabModel> tabs;
  final int activeTabIndex;

  const WebViewPage({
    super.key,
    required this.tabId,
    required this.initialUrl,
    required this.onTabUpdated,
    required this.onNewTabRequested,
    this.isIncognito = false,
    required this.tabs,
    required this.activeTabIndex,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _webViewController;
  final _urlFocusNode = FocusNode();
  final _urlEditController = TextEditingController();
  final _chatController = TextEditingController();

  double _progress = 0;
  Uri? _currentUrl;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isEditingUrl = false;

  // Context state
  bool _isYoutubeVideo = false;
  bool _isSocialMediaPlatform = false;
  bool _isGithubRepo = false;
  bool _isSearchPage = false;
  bool _showSummariseFab = false;

  // FAB state
  Offset? _fabPosition;
  bool _isFabVisible = true;
  bool _isDragging = false;

  // URL Polling State
  Timer? _urlUpdateTimer; 
  
  final _usageLimitService = UsageLimitService();

  final GlobalKey webViewKey = GlobalKey();

  late InAppWebViewSettings settings;

  // Standard Mobile User Agent
  static const String _mobileUserAgent = 
      "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36";

  final CookieManager _cookieManager = CookieManager.instance();

  @override
  void initState() {
    super.initState();
    _currentUrl = Uri.tryParse(widget.initialUrl);
    _urlEditController.text = widget.initialUrl;

    settings = InAppWebViewSettings(
      userAgent: _mobileUserAgent, 
      preferredContentMode: UserPreferredContentMode.MOBILE, 
      
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      domStorageEnabled: true,
      thirdPartyCookiesEnabled: true,
      supportMultipleWindows: true,
      safeBrowsingEnabled: true,
      allowFileAccess: true,
      allowContentAccess: true,
      allowsInlineMediaPlayback: true,
      mediaPlaybackRequiresUserGesture: false,
      transparentBackground: false,
      incognito: widget.isIncognito,
      clearCache: false,
      disableDefaultErrorPage: true,
      
      useShouldOverrideUrlLoading: true,
      useOnLoadResource: true,
    );

    _urlFocusNode.addListener(() {
      if (!_urlFocusNode.hasFocus) {
        setState(() => _isEditingUrl = false);
      }
    });

    _updatePageContext(_currentUrl);
    _restoreCookiesIfAny();
    _loadFabVisibility();
    _loadFabPosition();

    // FIX 2: Robust initial FAB position calculation using clamping
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _fabPosition == null) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Calculate a safe Y position: 60% down the screen, but constrained.
        // Min height (below AppBar) is approx kToolbarHeight + 10.
        // Max height (above Bottom NavBar) is approx 150px from the bottom.
        const double bottomNavBarHeight = 100.0;
        final double maxSafeDy = screenHeight - bottomNavBarHeight - 10.0;
        final double minSafeDy = kToolbarHeight + 10.0;
        
        final safeDy = (screenHeight * 0.60).clamp(minSafeDy, maxSafeDy);
        
        setState(() {
          _fabPosition = Offset(screenWidth - 80, safeDy);
        });
        _saveFabPosition(_fabPosition!); // Save the initial position
      }
    });
  }

  void _startUrlPolling() {
    _urlUpdateTimer?.cancel();
    _urlUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_webViewController != null) {
        _webViewController!.callAsyncJavaScript(
          functionBody: """
            const currentUrl = window.location.href;
            window.flutter_inappwebview.callHandler('onUpdateUrl', currentUrl);
          """
        );
      } else {
        timer.cancel();
      }
    });
  }

  void _onUpdateUrl(List<dynamic> args) {
    if (args.isEmpty) return;
    final newUrlString = args.first.toString();
    final newUri = Uri.tryParse(newUrlString);
    
    if (newUri != null && newUri.toString() != _currentUrl.toString()) {
      if (!mounted) return;
      setState(() {
        _currentUrl = newUri;
        _urlEditController.text = newUri.toString();
      });
      widget.onTabUpdated(widget.tabId, newUri.toString(), null, null);
      _updatePageContext(newUri);
    }
  }

  @override
  void dispose() {
    _saveCookies(); 
    _urlFocusNode.dispose();
    _urlEditController.dispose();
    _chatController.dispose();
    _urlUpdateTimer?.cancel(); 
    super.dispose();
  }

  Future<void> _loadFabPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final dx = prefs.getDouble('fabDx');
    final dy = prefs.getDouble('fabDy');
    if (dx != null && dy != null) {
      setState(() {
        _fabPosition = Offset(dx, dy);
      });
    }
  }

  Future<void> _saveFabPosition(Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fabDx', position.dx);
    await prefs.setDouble('fabDy', position.dy);
  }

  Future<void> _loadFabVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFabVisible = prefs.getBool('isFabVisible') ?? true;
    });
  }

  Future<void> _saveFabVisibility(bool isVisible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFabVisible', isVisible);
  }

  Future<void> _restoreCookiesIfAny() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('aurix_cookies');
      if (raw == null || raw.isEmpty) return;

      for (final pair in raw.split(';')) {
        final idx = pair.indexOf('=');
        if (idx <= 0) continue;
        final name = pair.substring(0, idx);
        final value = pair.substring(idx + 1);
        try {
          await _cookieManager.setCookie(
            url: WebUri("https://www.google.com"),
            name: name,
            value: value,
            domain: ".google.com",
            isSecure: true,
            sameSite: HTTPCookieSameSitePolicy.NONE,
          );
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _saveCookies() async {
    try {
      final cookies = await _cookieManager.getCookies(url: WebUri("https://www.google.com"));
      if (cookies == null || cookies.isEmpty) return;
      final pairs = cookies.map((c) => '${c.name}=${c.value}').join(';');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('aurix_cookies', pairs);
    } catch (_) {}
  }

  void _updatePageContext(Uri? url) {
    if (url == null) return;
    final host = url.host;
    final path = url.path;

    setState(() {
      _isYoutubeVideo = host.contains('youtube.com') || host.contains('youtu.be');
      _isSocialMediaPlatform = AppConstant.SOCIAL_MEDIA_DOMAINS.any((domain) => host.contains(domain)) && !_isYoutubeVideo;
      _isGithubRepo = AppConstant.CODE_HOSTING_DOMAINS.any((domain) => host.contains(domain));
      _isSearchPage = AppConstant.SEARCH_ENGINE_DOMAINS.any((domain) => host.contains(domain)) && (path.contains('/search') || path == '/');
      _showSummariseFab = (_isYoutubeVideo || !_isSocialMediaPlatform) && !_isSearchPage && !widget.isIncognito;
    });
  }

  Future<void> _handleDownload(DownloadStartRequest request) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage permission denied.')));
      return;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final filePath = '${documentsDir.path}/${request.suggestedFilename}';
    final downloadId = await DownloadService.addDownload(url: request.url.toString(), filename: request.suggestedFilename ?? 'download');

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading ${request.suggestedFilename}...')));

    try {
      final response = await http.get(request.url);
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      await DownloadService.updateDownloadStatus(id: downloadId, status: 'completed', filePath: filePath);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download complete: ${request.suggestedFilename}')));
    } catch (e) {
      await DownloadService.updateDownloadStatus(id: downloadId, status: 'failed');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed. Please check your connection.')));
    }
  }

  Future<void> _navigateToAiChat({String? initialMessage}) async {
    if (_webViewController == null || _currentUrl == null) return;
    if (initialMessage == null || initialMessage.trim().isEmpty) return;

    // Check rate limits for ALL chat/summary interactions
    final isSummary = initialMessage.toLowerCase().startsWith('summarize');
    String limitKey;
    int cooldown;
    
    final isPaid = await SupabaseService.isPaidUser();
    
    if (_isYoutubeVideo) {
      limitKey = UsageLimitService.KEY_LAST_YOUTUBE_SUMMARY;
      cooldown = isPaid ? AppConstant.PAID_YOUTUBE_SUMMARY_COOLDOWN_MINUTES : AppConstant.YOUTUBE_SUMMARY_COOLDOWN_MINUTES;
    } else {
      limitKey = UsageLimitService.KEY_LAST_ARTICLE_SUMMARY;
      cooldown = isPaid ? AppConstant.PAID_ARTICLE_SUMMARY_COOLDOWN_MINUTES : AppConstant.ARTICLE_SUMMARY_COOLDOWN_MINUTES;
    }

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

    _chatController.clear();
    FocusScope.of(context).unfocus();

    String pageContext;
    String systemPrompt;
    String chatTitle;

    bool isLoadingDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Preparing AI assistant...", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );

    try {
      if (_isYoutubeVideo) {
        Uri ytUri = _currentUrl!;
        final youtubeUrl = ytUri.toString();
        final apiUrl = await Uri.parse('http://localhost:3000/aurix/yt/?link=${Uri.encodeComponent(youtubeUrl)}');
        
        final response = await http.get(apiUrl);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['transcript'] != null) {
            pageContext = data['transcript'];
            systemPrompt = "You are a video content analyst. Use the provided video transcript to answer questions. The transcript is: \n\n$pageContext";
            chatTitle = "AI Video Assistant";
          } else {
            throw Exception(data['error'] ?? 'Failed to get transcript from API.');
          }
        } else {
          throw Exception('API request failed with status: ${response.statusCode} body: ${response.body}');
        }
      } else if (_isGithubRepo) {
        final codeContent = await _webViewController!.evaluateJavascript(source: "document.body.innerText");
        pageContext = codeContent?.toString().trim() ?? '';
        systemPrompt = "You are a senior developer analyzing this repository.";
        chatTitle = "AI Code Assistant";
      } else {
        final pageContent = await _webViewController!.evaluateJavascript(source: "document.body.innerText");
        pageContext = pageContent?.toString().trim() ?? '';
        systemPrompt = "You are a content writer summarizing and answering about this page.";
        chatTitle = "AI Article Assistant";
      }

      if (mounted && isLoadingDialogShowing) {
        Navigator.pop(context);
        isLoadingDialogShowing = false;
      }
      
      if (pageContext.isEmpty) throw Exception('Empty page content.');

      // Mark action as used on success
      await _usageLimitService.markActionUsed(limitKey);
      
      // Track Summary Analytics (Anonymous)
      if (isSummary) {
        SupabaseService.trackSummary();
      } else {
        SupabaseService.trackChat();
      }

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AiChatPage(
          pageContext: pageContext,
          systemPrompt: systemPrompt,
          chatTitle: chatTitle,
          initialMessage: initialMessage,
        )));
      }
    } catch (e) {
      // Only pop the dialog if it's still showing. Do not close the tab.
      if (mounted && isLoadingDialogShowing && Navigator.canPop(context)) {
        Navigator.pop(context);
        isLoadingDialogShowing = false;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to prepare AI chat. Please try again.'), backgroundColor: AppConstant.ERROR_COLOR));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_canGoBack) {
          _webViewController?.goBack();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: widget.isIncognito ? AppConstant.INCOGNITO_COLOR : Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      InAppWebView(
                        key: webViewKey,
                        initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
                        initialSettings: settings,
                        onWebViewCreated: (controller) async {
                          _webViewController = controller;
                          // Register the JavaScript Handler for URL Polling
                          controller.addJavaScriptHandler(
                            handlerName: 'onUpdateUrl', 
                            callback: _onUpdateUrl,
                          );
                        },

                        // FIX 1: Handle new windows by loading the URL in the current WebView to unblock auth flows
                        onCreateWindow: (controller, createWindowRequest) async {
                          final popupUrl = createWindowRequest.request.url;
                          if (popupUrl != null) {
                            // Force the pop-up/new-tab URL to load in the current view to ensure 
                            // authentication processes (like 'Continue with Google') complete.
                            controller.loadUrl(urlRequest: URLRequest(url: popupUrl));
                          }
                          // Returning true tells the WebView the request was handled.
                          return true; 
                        },

                        // Deep Link Blocking Logic
                        shouldOverrideUrlLoading: (controller, navigationAction) async {
                          final uri = navigationAction.request.url;
                          if (uri == null) return NavigationActionPolicy.ALLOW;

                          final scheme = uri.scheme.toLowerCase();
                          
                          if (['http', 'https', 'file', 'about', 'data', 'javascript', 'blob', 'chrome'].contains(scheme)) {
                            return NavigationActionPolicy.ALLOW;
                          }
                          
                          return NavigationActionPolicy.CANCEL;
                        },

                        onLoadStart: (controller, url) {
                          if (!mounted) return;
                          _urlUpdateTimer?.cancel(); // Stop polling during a full page load
                          setState(() {
                            _currentUrl = url;
                            _urlEditController.text = url.toString();
                          });
                          widget.onTabUpdated(widget.tabId, url.toString(), null, null);
                          _updatePageContext(url);
                        },

                        onLoadStop: (controller, url) async {
                          if (!mounted || url == null) return;
                          final newUrl = url.toString();
                          
                          _canGoBack = await controller.canGoBack();
                          _canGoForward = await controller.canGoForward();
                          final newTitle = await controller.getTitle();
                          if (!widget.isIncognito) {
                            try {
                              final newContent = await _webViewController!.evaluateJavascript(source: "document.body.innerText");
                              widget.onTabUpdated(widget.tabId, newUrl, newTitle, newContent?.toString().trim().replaceAll(RegExp(r'\s+'), ' '));
                            } catch (_) {}
                          } else {
                            widget.onTabUpdated(widget.tabId, newUrl, newTitle, null);
                          }
                          setState(() => _progress = 0);
                          _updatePageContext(url);
                          _startUrlPolling(); // Start polling after page load completes
                          
                          // Add to Local History
                          if (!widget.isIncognito) {
                            LocalHistoryService.addHistoryItem(
                              url: newUrl,
                              title: newTitle,
                            );
                          }
                        },

                        onProgressChanged: (controller, progress) {
                          if (!mounted) return;
                          setState(() {
                            _progress = progress / 100;
                          });
                        },

                        onDownloadStartRequest: (controller, downloadStartRequest) {
                          _handleDownload(downloadStartRequest);
                        },
                      ),

                      if (_progress > 0 && _progress < 1)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(AppConstant.ACCENT_COLOR),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildBottomNavBar(),
              ],
            ),
            if (_isFabVisible) _buildDraggableFab(),
            if (_isDragging) _buildDustbin(),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableFab() {
    if (_fabPosition == null) {
      return Container(); 
    }
    return Positioned(
      left: _fabPosition!.dx,
      top: _fabPosition!.dy,
      child: Draggable(
        feedback: _buildFloatingActionButtons(),
        childWhenDragging: Container(),
        onDragStarted: () {
          setState(() {
            _isDragging = true;
          });
        },
        onDragUpdate: (details) {
          setState(() {
            _fabPosition = details.localPosition;
          });
        },
        onDragEnd: (details) {
          setState(() {
            _isDragging = false;
            final screenHeight = MediaQuery.of(context).size.height;
            
            // FIX 3: Robust clamping for drag-and-drop position
            // Min height (below AppBar) is approx kToolbarHeight + 10.
            // Max height (above Bottom NavBar) is approx 150px from the bottom.
            const double maxSafeDy = 150.0;
            const double minSafeDy = kToolbarHeight + 10.0; 
            
            final newPosition = Offset(
              details.offset.dx.clamp(0, MediaQuery.of(context).size.width - 60),
              details.offset.dy.clamp(minSafeDy, screenHeight - maxSafeDy),
            );
            
            _fabPosition = newPosition;
            _saveFabPosition(newPosition);
          });
        },
        child: _buildFloatingActionButtons(),
      ),
    );
  }

  Widget _buildDustbin() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: DragTarget<Widget>(
          builder: (context, candidateData, rejectedData) {
            return Icon(
              Icons.delete_outline,
              size: 40,
              color: candidateData.isNotEmpty ? AppConstant.ERROR_COLOR : Colors.grey,
            );
          },
          onWillAccept: (data) => true,
          onAccept: (data) {
            setState(() {
              _isFabVisible = false;
              _isDragging = false;
            });
            _saveFabVisibility(false);
          },
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isSocialMediaPlatform)
            FloatingActionButton.extended(
              heroTag: 'social_fab',
              onPressed: _showGenerateInputDialog,
              label: const Text('Generate Input'),
              icon: const Icon(Icons.auto_awesome),
              backgroundColor: AppConstant.PRIMARY_COLOR,
            ),
          const SizedBox(height: AppConstant.PADDING_SMALL),
          if (_showSummariseFab)
            FloatingActionButton.extended(
              heroTag: 'summarise_fab',
              onPressed: () => _navigateToAiChat(
                  initialMessage: _isYoutubeVideo
                      ? "Summarize this video in 180 words."
                      : "Summarize this page in 180 words."),
              label: Text(_isYoutubeVideo ? 'Summarize Video' : 'Summarize'),
              icon: const Icon(Icons.short_text),
              backgroundColor: AppConstant.PRIMARY_COLOR,
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(icon: const Icon(Icons.home_outlined), tooltip: 'Close Tab', onPressed: () => Navigator.of(context).pop()),
      title: GlassmorphicContainer(
        blur: 10,
        borderRadius: BorderRadius.circular(AppConstant.BORDER_RADIUS_XL),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstant.PADDING_SMALL),
          child: _isEditingUrl ? _buildUrlTextField() : _buildUrlDisplay(),
        ),
      ),
      actions: [
        if (widget.isIncognito) const Icon(Icons.security),
        IconButton(
          icon: const Icon(Icons.bookmark_border),
          tooltip: 'Add Bookmark',
          onPressed: () async {
            if (_currentUrl == null) return;
            
            if (!SupabaseService.isAuthenticated) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please sign in to add bookmarks')),
                );
              }
              return;
            }

            try {
              final title = await _webViewController?.getTitle();
              await SupabaseService.addBookmark(
                url: _currentUrl.toString(),
                title: title ?? _currentUrl.toString(),
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark added!')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            }
          },
        ),
        IconButton(icon: const Icon(Icons.maps_ugc_outlined), tooltip: 'Chat Tabs', onPressed: _showTabsPage),
      ],
    );
  }

  Widget _buildUrlDisplay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditingUrl = true;
          _urlEditController.selection = TextSelection(baseOffset: 0, extentOffset: _urlEditController.text.length);
          _urlFocusNode.requestFocus();
        });
      },
      child: Container(
        height: kToolbarHeight,
        color: Colors.transparent,
        child: Row(
          children: [
            const Icon(Icons.lock, size: 16),
            const SizedBox(width: AppConstant.PADDING_SMALL),
            Expanded(child: Text(_currentUrl.toString(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlTextField() {
    return TextField(controller: _urlEditController, focusNode: _urlFocusNode, autofocus: true, onSubmitted: (_) => _navigate(), decoration: const InputDecoration(border: InputBorder.none), style: const TextStyle(fontSize: 14));
  }

  void _navigate() {
    setState(() => _isEditingUrl = false);
    final input = _urlEditController.text.trim();
    if (input.isEmpty) return;
    Uri? uri = Uri.tryParse(input);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(uri.toString())));
    } else {
      SupabaseService.trackSearch();
      Uri searchUri = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(input)}');
      _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(searchUri.toString())));
    }
  }

  Future<void> _showTabsPage() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => TabsPage(tabs: widget.tabs, activeTabIndex: widget.activeTabIndex, onTabSelected: (index) => Navigator.pop(ctx, {'action': 'select', 'index': index}), onNewTab: () => Navigator.pop(ctx, {'action': 'new'}), onCloseTab: (index) => Navigator.pop(ctx, {'action': 'close', 'index': index}))));
    if (result == null) return;
    if (result is Map && result['action'] == 'select') {
      final selectedIndex = result['index'];
      if (selectedIndex != widget.activeTabIndex) {
        if (mounted) Navigator.pop(context, result);
      }
    } else if (mounted) {
      Navigator.pop(context, result);
    }
  }

  Widget _buildBottomNavBar() {
    return GlassmorphicContainer(borderRadius: BorderRadius.zero, blur: 20, child: SafeArea(top: false, child: widget.isIncognito ? const SizedBox.shrink() : _buildAiChatBar()));
  }

  Widget _buildAiChatBar() {
    String hintText = _isGithubRepo ? 'Ask about this code...' : _isYoutubeVideo ? 'Ask about this video...' : 'Ask about this page...';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          Expanded(child: TextField(controller: _chatController, decoration: InputDecoration(hintText: hintText, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstant.BORDER_RADIUS_XL), borderSide: BorderSide.none), filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16)), onSubmitted: (value) => _navigateToAiChat(initialMessage: value))),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.send), onPressed: () => _navigateToAiChat(initialMessage: _chatController.text), style: IconButton.styleFrom(backgroundColor: AppConstant.PRIMARY_COLOR, foregroundColor: Colors.white)),
        ],
      ),
    );
  }

  void _showGenerateInputDialog() async {
    if (_webViewController == null || widget.isIncognito) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI generation disabled in incognito mode.')));
      return;
    }

    final result = await showModalBottomSheet<String>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: SocialContentGeneratorSheet(webViewController: _webViewController!, platform: _getPlatformFromUrl(_currentUrl))));
    if (result != null && result.isNotEmpty) _showGeneratedContentPopup(result);
  }

  String _getPlatformFromUrl(Uri? url) {
    if (url == null) return 'General';
    String host = url.host;
    if (host.contains('linkedin')) return 'LinkedIn';
    if (host.contains('x.com') || host.contains('twitter.com')) return 'X';
    if (host.contains('reddit')) return 'Reddit';
    if (host.contains('instagram')) return 'Instagram';
    if (host.contains('dev.to')) return 'Dev.to';
    return 'General';
  }

  void _showGeneratedContentPopup(String content) {
    showDialog(context: context, builder: (context) => AlertDialog(title: Text('Generated Content', style: GoogleFonts.poppins()), content: SingleChildScrollView(child: Text(content)), actions: [TextButton(child: const Text('Copy & Close'), onPressed: () { Clipboard.setData(ClipboardData(text: content)); Navigator.of(context).pop(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content copied to clipboard!'))); }), TextButton(child: const Text('Close'), onPressed: () => Navigator.of(context).pop())]));
  }
}
