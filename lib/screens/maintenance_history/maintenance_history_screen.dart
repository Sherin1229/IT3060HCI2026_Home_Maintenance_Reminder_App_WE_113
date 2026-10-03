import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/maintenance_model.dart';
import '../../providers/maintenance_provider.dart';
import 'maintenance_widgets.dart';

class MaintenanceHistoryScreen extends StatefulWidget {
  const MaintenanceHistoryScreen({super.key});
  @override
  State<MaintenanceHistoryScreen> createState() =>
      _MaintenanceHistoryScreenState();
}

class _MaintenanceHistoryScreenState extends State<MaintenanceHistoryScreen> {
  String _query = '';
  MaintenanceStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view maintenance history.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance History'),
        actions: [
          IconButton(
            onPressed: _showFilterInfo,
            icon: const Icon(Icons.tune),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: StreamBuilder<List<MaintenanceRecord>>(
        stream: context.read<MaintenanceProvider>().getRecords(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load maintenance history.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records =
              snapshot.data!.where((record) {
                  final query =
                      '${record.title} ${record.appliance} ${record.location}'
                          .toLowerCase();
                  return query.contains(_query.toLowerCase()) &&
                      (_filter == null || record.status == _filter);
                }).toList()
                ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
          final grouped = <String, List<MaintenanceRecord>>{};
          for (final record in records) {
            grouped
                .putIfAbsent(formatMonth(record.scheduledDate), () => [])
                .add(record);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search records...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == null,
                      onSelected: () => setState(() => _filter = null),
                    ),
                    _FilterChip(
                      label: 'Completed',
                      selected: _filter == MaintenanceStatus.completed,
                      onSelected: () =>
                          setState(() => _filter = MaintenanceStatus.completed),
                    ),
                    _FilterChip(
                      label: 'Upcoming',
                      selected: _filter == MaintenanceStatus.upcoming,
                      onSelected: () =>
                          setState(() => _filter = MaintenanceStatus.upcoming),
                    ),
                    _FilterChip(
                      label: 'Overdue',
                      selected: _filter == MaintenanceStatus.overdue,
                      onSelected: () =>
                          setState(() => _filter = MaintenanceStatus.overdue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Center(child: Text('No maintenance records found.')),
                ),
              ...grouped.entries.expand(
                (entry) => [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ...entry.value.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MaintenanceRecordTile(
                        record: record,
                        onTap: () => context.push(
                          '/maintenance/details',
                          extra: record.id,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterInfo() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Use the status chips to filter your maintenance records.'),
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
