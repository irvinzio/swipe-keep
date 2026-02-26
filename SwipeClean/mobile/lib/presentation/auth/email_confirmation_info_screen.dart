import 'package:flutter/material.dart';

class EmailConfirmationInfoScreen extends StatelessWidget {
  final String email;

  const EmailConfirmationInfoScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm your email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'A confirmation email was sent to $email. Please confirm your email before logging in.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
