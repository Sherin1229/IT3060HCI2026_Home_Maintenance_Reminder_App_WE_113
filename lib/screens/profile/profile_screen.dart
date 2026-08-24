import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'My Profile',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'Manage account preferences and home settings.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
