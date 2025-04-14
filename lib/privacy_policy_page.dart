import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'We value your privacy. No personal data is shared without your permission.\n\nPlease refer to our policy for details.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}