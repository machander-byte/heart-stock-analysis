import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Your data stays on this device for this demo. No personal data is sent to any server except the prediction API when you request a prediction.'),
      ),
    );
  }
}

