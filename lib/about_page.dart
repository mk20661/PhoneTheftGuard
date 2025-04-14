import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'PhoneTheftGuard v1.0\n\nAn app to help users stay alert against phone theft in London.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}