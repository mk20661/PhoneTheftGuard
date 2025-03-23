import 'package:flutter/material.dart';
import 'global_data.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _currentAddress;
  @override
  void initState() {
    super.initState();
    _currentAddress = globalAddress ?? "Loading...";
    Future.delayed(Duration(seconds: 1), () {
      if (globalAddress != null) {
        setState(() {
          _currentAddress = globalAddress!;
        });
      }
    });
  }

  bool _notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        title: const Text("Setting"),
        backgroundColor: Colors.lightBlue[100],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              "User Name",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(_currentAddress, style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text(
                "Personal Information",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text(
                "Notifications",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
