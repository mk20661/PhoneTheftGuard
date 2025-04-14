import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'src/theme_provider.dart';
import 'src/locale_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _locationWarningEnabled = true;
  String _selectedMapStyle = "Heatmap";
  String _selectedLanguage = "English";
  String _selectedTheme = "System";

  final List<String> _mapStyles = ['Heatmap', 'Standard'];
  final List<String> _languages = ['English', '中文'];
  final List<String> _themes = ['Light', 'Dark', 'System'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FA),
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: const Color(0xFFB3D1F2),
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle("Account"),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Edit Profile"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.push('/profile', extra: {'from': 'settings'});
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text("Change Password"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && user.email != null) {
                      context.push(
                        '/sign-in/forgot-password?email=${Uri.encodeComponent(user.email!)}',
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSectionTitle("App Settings"),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text("Enable Notifications"),
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() {
                      _notificationsEnabled = val;
                    });
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.warning),
                  title: const Text("Location Safety Alert"),
                  value: _locationWarningEnabled,
                  onChanged: (val) {
                    setState(() {
                      _locationWarningEnabled = val;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text("Map Style"),
                  trailing: DropdownButton<String>(
                    value: _selectedMapStyle,
                    underline: const SizedBox(),
                    items:
                        _mapStyles.map((style) {
                          return DropdownMenuItem(
                            value: style,
                            child: Text(style),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMapStyle = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("Language"),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: const SizedBox(),
                    items:
                        _languages.map((lang) {
                          return DropdownMenuItem(
                            value: lang,
                            child: Text(lang),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                      final localeCode = value == '中文' ? 'zh' : 'en';
                      Provider.of<LocaleProvider>(
                        context,
                        listen: false,
                      ).setLocale(localeCode);
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text("Theme"),
                  trailing: DropdownButton<String>(
                    value: _selectedTheme,
                    underline: const SizedBox(),
                    items:
                        _themes.map((theme) {
                          return DropdownMenuItem(
                            value: theme,
                            child: Text(theme),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTheme = value!;
                      });
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).setTheme(value!);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSectionTitle("Info & Privacy"),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text("About App"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.push('/about');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text("Privacy Policy"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.push('/privacy');
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text("Version"),
                  trailing: Text("v1.0.0"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Log Out", style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text("Confirm Logout"),
                        content: const Text(
                          "Are you sure you want to log out?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text("Log Out"),
                          ),
                        ],
                      ),
                );
                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/sign-in');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}
