import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _topics = [
    (
      'How do I add an appliance?',
      'Open Appliances from the bottom navigation, then use Add Appliance and complete the appliance details.',
    ),
    (
      'How do I create a maintenance reminder?',
      'Open Reminders, tap the plus button, enter the reminder details, configure its schedule, and save it.',
    ),
    (
      'How do I manage a warranty?',
      'Open Warranties to add, view, edit, or delete warranty information and its attached document.',
    ),
    (
      'How do I view maintenance history?',
      'Open the maintenance area from the dashboard to review scheduled and completed maintenance records.',
    ),
    (
      'How do notifications work?',
      'The Notifications screen shows in-app updates. Notification Settings stores your alert preferences and quiet hours.',
    ),
    (
      'How do I update my profile?',
      'Open Profile and choose Edit Profile. You can update your full name and phone number.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
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
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            const Icon(
              Icons.help_outline_rounded,
              size: 52,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 12),
            Text(
              'How can we help you?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Find quick guidance for common HomiQ tasks.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Card(
              child: Column(
                children: [
                  for (var index = 0; index < _topics.length; index++) ...[
                    ExpansionTile(
                      title: Text(_topics[index].$1),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _topics[index].$2,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    if (index != _topics.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
