import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_profile_model.dart';
import 'app_constant.dart';
import 'gemini_service.dart';
import 'glassmorphic_container.dart';
import 'premium_limit_popup.dart';
import 'supabase_service.dart';
import 'usage_limit_service.dart';

class SocialContentGeneratorSheet extends StatefulWidget {
  final InAppWebViewController webViewController;
  final String platform;

  const SocialContentGeneratorSheet({
    super.key,
    required this.webViewController,
    required this.platform,
  });

  @override
  State<SocialContentGeneratorSheet> createState() =>
      _SocialContentGeneratorSheetState();
}

class _SocialContentGeneratorSheetState
    extends State<SocialContentGeneratorSheet> {
  // State variables
  List<AiProfile> _profiles = [];
  AiProfile? _selectedProfile;
  String _selectedInputType = 'Post';
  final TextEditingController _contextController = TextEditingController();
  String _selectedTone = 'Normal';
  String _selectedLanguage = 'Default';
  double _wordCount = 100;
  bool _isLoadingProfiles = true;
  bool _isGenerating = false;

  // Options
  final List<String> _inputTypes = ['Post', 'Comment', 'Reply'];
  final List<String> _tones = ['Funny', 'Sarcastic', 'Flirty', 'Promotional', 'Insightful', 'Formal', 'Normal'];
  final List<String> _languages = ['Default', 'English', 'Spanish', 'French', 'German', 'Hindi'];

  final _usageLimitService = UsageLimitService();

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoadingProfiles = true);
    try {
      _profiles = await SupabaseService.getAiProfiles();
    } catch (e) {
      // Ignore, user may not have a profile yet
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfiles = false);
      }
    }
  }

  Future<void> _handleGenerate() async {
    if (_isGenerating) return;

    final isPaid = await SupabaseService.isPaidUser();
    final cooldown = isPaid ? AppConstant.PAID_GENERATE_CONTENT_COOLDOWN_MINUTES : AppConstant.GENERATE_CONTENT_COOLDOWN_MINUTES;

    if (!await _usageLimitService.canPerformAction(UsageLimitService.KEY_LAST_CONTENT_GENERATION, cooldown)) {
      final remaining = await _usageLimitService.getTimeUntilNextAction(UsageLimitService.KEY_LAST_CONTENT_GENERATION, cooldown);
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

    setState(() => _isGenerating = true);

    try {
      final pageContent = await widget.webViewController.evaluateJavascript(source: "document.body.innerText");
      
      final result = await GeminiService.generateSocialContent(
        platform: widget.platform,
        profileContext: _selectedProfile?.profileContext,
        inputType: _selectedInputType,
        userContext: _contextController.text,
        selectedTone: _selectedTone,
        language: _selectedLanguage,
        wordCount: _wordCount.toInt(),
        pageContent: pageContent?.toString(),
      );

      await _usageLimitService.markActionUsed(UsageLimitService.KEY_LAST_CONTENT_GENERATION);
      
      // Track Content Generation Analytics (Anonymous)
      SupabaseService.trackContentGeneration();

      if (mounted) {
        Navigator.pop(context, result);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while generating content. Please try again.'),
            backgroundColor: AppConstant.ERROR_COLOR,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: AppConstant.PADDING_LARGE),
              Text('Generate Content for ${widget.platform}',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppConstant.PADDING_LARGE),
              if (_isLoadingProfiles)
                const Center(child: CircularProgressIndicator())
              else
                ..._buildForm(),
              const SizedBox(height: AppConstant.PADDING_LARGE),
              _isGenerating
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: ElevatedButton.icon(
                        onPressed: _handleGenerate,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 16),
                          textStyle: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
              const SizedBox(height: AppConstant.PADDING_MEDIUM),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildForm() {
    return [
      Row(
        children: [
          Expanded(child: _buildProfileDropdown()),
          const SizedBox(width: AppConstant.PADDING_MEDIUM),
          Expanded(child: _buildDropdown('Type', _selectedInputType, _inputTypes, (val) => setState(() => _selectedInputType = val!))),
        ],
      ),
      const SizedBox(height: AppConstant.PADDING_MEDIUM),
      TextFormField(
        controller: _contextController,
        decoration: const InputDecoration(
          labelText: 'Optional Context',
          hintText: 'e.g., "Make it a question"',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: AppConstant.PADDING_LARGE),
      Text('Tone', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      const SizedBox(height: AppConstant.PADDING_SMALL),
      Wrap(
        spacing: AppConstant.PADDING_SMALL,
        runSpacing: AppConstant.PADDING_SMALL,
        children: _tones
            .map((tone) => ChoiceChip(
                  label: Text(tone),
                  selected: _selectedTone == tone,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedTone = tone);
                  },
                ))
            .toList(),
      ),
      const SizedBox(height: AppConstant.PADDING_LARGE),
      _buildDropdown('Language', _selectedLanguage, _languages, (val) => setState(() => _selectedLanguage = val!)),
      const SizedBox(height: AppConstant.PADDING_LARGE),
      Text('Word Count: ${_wordCount.toInt()}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      Slider(
        value: _wordCount,
        min: 2,
        max: 150,
        divisions: 25,
        label: _wordCount.round().toString(),
        onChanged: (double value) {
          setState(() {
            _wordCount = value;
          });
        },
      ),
    ];
  }

  Widget _buildProfileDropdown() {
    return DropdownButtonFormField<AiProfile?>(
      value: _selectedProfile,
      hint: const Text('Select Profile'),
      decoration: const InputDecoration(
        labelText: 'Profile',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: AppConstant.PADDING_MEDIUM, vertical: AppConstant.PADDING_MEDIUM),
      ),
      items: [
        const DropdownMenuItem<AiProfile?>(
          value: null,
          child: Text('Default Profile'),
        ),
        ..._profiles.map((profile) => DropdownMenuItem<AiProfile?>(
          value: profile,
          child: Text(profile.profileName),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _selectedProfile = value;
        });
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppConstant.PADDING_MEDIUM, vertical: AppConstant.PADDING_MEDIUM),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }
}
