import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class AppliancesScreen extends StatelessWidget {
  const AppliancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appliances'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'My Appliances',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'Register and track your household appliances here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
