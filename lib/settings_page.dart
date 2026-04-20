import 'package:flutter/material.dart';
import 'package:aurix_browser/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  ThemeMode _themeMode = ThemeMode.system;
  String _searchEngine = 'https://www.google.com/search?q=';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _themeMode = await _settingsService.getThemeMode();
    _searchEngine = await _settingsService.getSearchEngine();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_themeMode.toString().split('.').last),
            onTap: () => _showThemeDialog(),
          ),
          ListTile(
            title: const Text('Default Search Engine'),
            subtitle: Text(_searchEngine),
            onTap: () => _showSearchEngineDialog(),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                value: ThemeMode.system,
                groupValue: _themeMode,
                onChanged: (value) {
                  _settingsService.setThemeMode(value!);
                  setState(() => _themeMode = value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: _themeMode,
                onChanged: (value) {
                  _settingsService.setThemeMode(value!);
                  setState(() => _themeMode = value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: _themeMode,
                onChanged: (value) {
                  _settingsService.setThemeMode(value!);
                  setState(() => _themeMode = value);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSearchEngineDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Search Engine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Google'),
                value: 'https://www.google.com/search?q=',
                groupValue: _searchEngine,
                onChanged: (value) {
                  _settingsService.setSearchEngine(value!);
                  setState(() => _searchEngine = value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('DuckDuckGo'),
                value: 'https://duckduckgo.com/?q=',
                groupValue: _searchEngine,
                onChanged: (value) {
                  _settingsService.setSearchEngine(value!);
                  setState(() => _searchEngine = value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('Bing'),
                value: 'https://www.bing.com/search?q=',
                groupValue: _searchEngine,
                onChanged: (value) {
                  _settingsService.setSearchEngine(value!);
                  setState(() => _searchEngine = value);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
