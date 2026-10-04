import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/app_logo.dart';

class AboutHomiQScreen extends StatelessWidget {
  const AboutHomiQScreen({super.key});

  static const _features = [
    'Appliance management',
    'Maintenance tracking and history',
    'Scheduled maintenance reminders',
    'Warranty and document management',
    'In-app notifications and preferences',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About HomiQ'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back to profile',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          children: [
            const Center(child: AppLogo(height: 92, width: 92)),
            const SizedBox(height: 12),
            Text(
              'HomiQ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'HomiQ helps organize home appliances, maintenance activities, reminders, warranties, documents, and related records in one place.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Features',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    for (final feature in _features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppColors.secondaryTeal,
                              size: 21,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(feature)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('App Version'),
                trailing: Text('1.0.0 (1)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
