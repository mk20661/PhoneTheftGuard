import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'PhoneTheftGuard v1.0\n\n'
          'PhoneTheftGuard is a mobile app designed to help users stay alert against phone theft in London. '
          'The app uses real-world crime data and GPS to detect when users enter high-risk areas.\n\n'
          'Key features include:\n'
          '• Real-time alerts when entering dangerous locations\n'
          '• Monthly heatmaps of phone theft incidents\n'
          '• Community sharing of theft experiences\n'
          '• Location-based warning system with optional notifications\n\n'
          'This app was developed as part of a university project aiming to raise awareness and promote safer behaviors when using phones in public. '
          'Data sources include publicly available crime statistics.\n\n'
          'Stay safe. Stay aware. PhoneTheftGuard helps you protect what matters.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}
