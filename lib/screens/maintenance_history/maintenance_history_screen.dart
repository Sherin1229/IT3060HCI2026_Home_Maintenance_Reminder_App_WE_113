import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import 'maintenance_models.dart';
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
    final records = maintenanceRecords.where((record) {
      final matchesQuery = '${record.title} ${record.appliance}'
          .toLowerCase()
          .contains(_query.toLowerCase());
      return matchesQuery && (_filter == null || record.status == _filter);
    }).toList()..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    final grouped = <String, List<MaintenanceRecord>>{};
    for (final record in records) {
      grouped
          .putIfAbsent(formatMonth(record.scheduledDate), () => [])
          .add(record);
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
      body: ListView(
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
                    onTap: () =>
                        context.push('/maintenance/details', extra: record),
                  ),
                ),
              ),
            ],
          ),
        ],
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
