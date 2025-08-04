import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wordstory/data/interfaces/user_interface.dart';

import '../providers/app_auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/gamification_provider.dart';
import '../widgets/achievement_badge.dart';
import '../data/config/achievements.dart';

/// User profile and settings screen.  Displays the current user's
/// information, allows editing the display name and avatar, toggling
/// theme and sync preferences, exporting data (stub) and displays
/// unlocked achievements.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _editingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount(UserInterface user) async {
    try {
      await user.deleteAccount();
      if (mounted) {
        // Navigator.of(context).pop(); // Go back or to splash/login screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // User must re-authenticate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in again to delete your account.')),
        );
        // Optionally, force sign-out and let user log in again
        await user.signOut();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  void _confirmDeleteAccount(UserInterface user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action cannot be undone. Are you sure you want to delete your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount(user);
    }
  }

  Future<void> _pickAvatar(UserInterface user) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await user.updateProfile(avatar: file);
    }
  }

  void _updateName(UserInterface user) async {
    await user.updateProfile(displayName: _nameController.text.trim());
    setState(() => _editingName = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final gamification = context.watch<GamificationProvider>().stats;
    final user = authProvider.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }
    final unlockedAchievements = gamification?.achievements ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) as ImageProvider : null,
                  child: user.photoURL == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _editingName
                          ? Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () => _updateName(user),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Text(user.displayName ?? 'Unnamed', style: Theme.of(context).textTheme.headlineSmall),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    setState(() {
                                      _editingName = true;
                                      _nameController.text = user.displayName ?? '';
                                    });
                                  },
                                ),
                              ],
                            ),
                      Text(user.email ?? '', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => _pickAvatar(user),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (val) => themeProvider.setThemeMode(val!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (val) => themeProvider.setThemeMode(val!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (val) => themeProvider.setThemeMode(val!),
            ),
            const SizedBox(height: 24),
            const Text('Achievements', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: achievementsCatalog.length,
              itemBuilder: (context, index) {
                final achievement = achievementsCatalog[index];
                final unlocked = unlockedAchievements.contains(achievement.id);
                return AchievementBadge(
                  achievement: achievement,
                  unlocked: unlocked,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                await user.signOut();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              onTap: () => _confirmDeleteAccount(user),
            ),
          ],
        ),
      ),
    );
  }
}
