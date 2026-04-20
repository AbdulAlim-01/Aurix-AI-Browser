import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_constant.dart';
import 'supabase_service.dart';
import 'ai_profile_model.dart';

class AiProfilePage extends StatefulWidget {
  const AiProfilePage({super.key});

  @override
  State<AiProfilePage> createState() => _AiProfilePageState();
}

class _AiProfilePageState extends State<AiProfilePage> {
  late Future<List<AiProfile>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    setState(() {
      _profilesFuture = SupabaseService.getAiProfiles();
    });
  }

  Future<void> _showProfileDialog({AiProfile? profile}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ProfileEditDialog(profile: profile),
    );

    if (result == true) {
      _loadProfiles();
    }
  }

  Future<void> _deleteProfile(String profileId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile?'),
        content: const Text('Are you sure you want to delete this profile? This action cannot be undone.'),
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
        await SupabaseService.deleteAiProfile(profileId);
        _loadProfiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile deleted.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Content Profiles', style: GoogleFonts.poppins()),
      ),
      body: FutureBuilder<List<AiProfile>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final profiles = snapshot.data ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Create up to 5 custom profiles to tailor AI-generated content to your personal or business needs. A 'Default' profile is always available for general use.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return ListTile(
                      leading: Icon(profile.profileType == 'business' ? Icons.business_center : Icons.person),
                      title: Text(profile.profileName),
                      subtitle: Text(
                        profile.profileContext,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _showProfileDialog(profile: profile)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppConstant.ERROR_COLOR),
                            onPressed: profile.id == null ? null : () => _deleteProfile(profile.id!),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<List<AiProfile>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.length < 5) {
            return FloatingActionButton.extended(
              onPressed: () => _showProfileDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Profile'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ProfileEditDialog extends StatefulWidget {
  final AiProfile? profile;
  const _ProfileEditDialog({this.profile});

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contextController;
  String _selectedType = 'personal';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.profileName ?? '');
    _contextController = TextEditingController(text: widget.profile?.profileContext ?? '');
    _selectedType = widget.profile?.profileType ?? 'personal';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        throw Exception("User not authenticated");
      }
      
      if (widget.profile == null) { // Create new
        final newProfile = AiProfile(
          userId: userId,
          profileName: _nameController.text,
          profileType: _selectedType,
          profileContext: _contextController.text,
        );
        await SupabaseService.createAiProfile(newProfile);
      } else { // Update existing
        final updatedProfile = widget.profile!
          ..profileName = _nameController.text
          ..profileType = _selectedType
          ..profileContext = _contextController.text;
        await SupabaseService.updateAiProfile(updatedProfile);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.profile == null ? 'Create Profile' : 'Edit Profile'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Profile Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'personal', child: Text('Personal')),
                  DropdownMenuItem(value: 'business', child: Text('Business')),
                ],
                onChanged: (value) => setState(() => _selectedType = value!),
                decoration: const InputDecoration(labelText: 'Profile Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contextController,
                decoration: const InputDecoration(
                  labelText: 'Context',
                  hintText: 'Describe yourself or your business...',
                ),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'Please provide context' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}