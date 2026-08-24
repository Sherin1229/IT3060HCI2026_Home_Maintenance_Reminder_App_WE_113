import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to ${AppConstants.appName}',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                AppConstants.appDescription,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Login (Go to Dashboard)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/signup'),
                child: const Text('Create an Account'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
