import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Join ${AppConstants.appName}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Register & Continue'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
