import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Privacy Policy\n\n'
          'We value your privacy. This app does not collect or store any personally identifiable information without your consent.\n\n'
          '1. Location Data:\n'
          'Your location is used solely to provide real-time alerts when entering high-risk theft zones. This data is never stored or shared.\n\n'
          '2. Notifications:\n'
          'The app may send you alerts based on your current location settings. These can be enabled or disabled at any time.\n\n'
          '3. Community Features:\n'
          'If you choose to post in the community section, your messages may be visible to other users, but no personal data is attached unless you explicitly provide it.\n\n'
          '4. Data Sharing:\n'
          'We do not sell, rent, or share your information with third parties.\n\n'
          'For any questions or concerns regarding this policy, please contact our support team.\n\n'
          'By using this app, you agree to the terms outlined in this privacy policy.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}
