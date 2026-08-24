import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class WarrantiesScreen extends StatelessWidget {
  const WarrantiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranties'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Warranty Tracker',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'Store and monitor warranty documents and expiration dates.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
