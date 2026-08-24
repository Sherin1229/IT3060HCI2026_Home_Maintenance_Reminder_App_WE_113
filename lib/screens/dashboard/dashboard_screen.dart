import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Maintenance History',
            onPressed: () => context.push('/maintenance-history'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dashboard Overview',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to your home maintenance dashboard!',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    children: [
                      const Text(
                        'Quick Summary Placeholder',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Total Appliances: 0\nPending Reminders: 0'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.push('/maintenance-history'),
                        child: const Text('View Maintenance History'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
