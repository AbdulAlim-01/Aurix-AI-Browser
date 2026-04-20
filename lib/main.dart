import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'app_constant.dart';
import 'auth_page.dart';
import 'home_page.dart';
import 'settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // -----------------------------------------------------------
  // 🧠 1. Prepare InAppWebView environment for Android & iOS
  // -----------------------------------------------------------
  try {
    // Enables inspection in debug & sets correct chromium environment.
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    // Optional: Pre-start safe-browsing (avoid "browser not secure" banner)
    // if (defaultTargetPlatform == TargetPlatform.android) {
    //   await InAppWebViewController.startSafeBrowsing();
    // }
  } catch (e) {
    debugPrint('WebView environment init failed: $e');
  }

  // -----------------------------------------------------------
  // 🗝️ 2. Initialize Supabase
  // -----------------------------------------------------------
  await Supabase.initialize(
    url: AppConstant.SUPABASE_URL,
    anonKey: AppConstant.SUPABASE_ANON_KEY,
  );

  final settingsService = SettingsService();
  final settingsController = SettingsController(settingsService);
  await settingsController.loadSettings();

  // -----------------------------------------------------------
  // 🚀 3. Launch the app with DevicePreview
  // -----------------------------------------------------------
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => AnimatedBuilder(
        animation: settingsController,
        builder: (BuildContext context, Widget? child) {
          return MyApp(settingsController: settingsController);
        },
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: AppConstant.APP_NAME,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppConstant.PRIMARY_COLOR,
        scaffoldBackgroundColor: AppConstant.BACKGROUND_COLOR_LIGHT,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: AppConstant.TEXT_PRIMARY),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF3A3FF),
          brightness: Brightness.light,
          primary: AppConstant.PRIMARY_COLOR,
          secondary: AppConstant.SECONDARY_COLOR,
          background: AppConstant.BACKGROUND_COLOR_LIGHT,
          surface: AppConstant.SURFACE_COLOR_LIGHT,
          error: AppConstant.ERROR_COLOR,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppConstant.PRIMARY_COLOR,
        scaffoldBackgroundColor: AppConstant.BACKGROUND_COLOR_DARK,
        useMaterial3: true,
        textTheme:
            GoogleFonts.interTextTheme(Theme.of(context).primaryTextTheme)
                .apply(bodyColor: AppConstant.TEXT_PRIMARY_DARK),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF3A3FF),
          brightness: Brightness.dark,
          primary: AppConstant.PRIMARY_COLOR,
          secondary: AppConstant.SECONDARY_COLOR,
          background: AppConstant.BACKGROUND_COLOR_DARK,
          surface: AppConstant.SURFACE_COLOR_DARK,
          error: AppConstant.ERROR_COLOR,
        ),
      ),
      themeMode: settingsController.themeMode,
      home: const AuthStateObserver(),
    );
  }
}

class AuthStateObserver extends StatefulWidget {
  const AuthStateObserver({super.key});

  @override
  State<AuthStateObserver> createState() => _AuthStateObserverState();
}

class _AuthStateObserverState extends State<AuthStateObserver> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Supabase.instance.client.auth.currentSession == null
        ? const AuthPage()
        : const HomePage();
  }
}

class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  final SettingsService _settingsService;

  late ThemeMode _themeMode;
  late String _searchEngine;

  ThemeMode get themeMode => _themeMode;
  String get searchEngine => _searchEngine;

  Future<void> loadSettings() async {
    _themeMode = await _settingsService.getThemeMode();
    _searchEngine = await _settingsService.getSearchEngine();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    await _settingsService.setThemeMode(newThemeMode);
  }

  Future<void> updateSearchEngine(String? newSearchEngine) async {
    if (newSearchEngine == null) return;
    if (newSearchEngine == _searchEngine) return;
    _searchEngine = newSearchEngine;
    notifyListeners();
    await _settingsService.setSearchEngine(newSearchEngine);
  }
}
