import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';

enum _WarrantyFilter { all, active, expiring, expired }

enum _WarrantyStatus { active, expiringSoon, expired }

enum _ExpiryPeriod { anyTime, within30Days, within3Months, within6Months }

enum _ApplianceType {
  all,
  refrigerator,
  washingMachine,
  airConditioner,
  television,
}

enum _WarrantySort { expiryEarliest, expiryLatest }

class _WarrantyItem {
  final String appliance;
  final String model;
  final _WarrantyStatus status;
  final String expiry;
  final DateTime expiryDate;
  final _ApplianceType applianceType;
  final IconData icon;

  const _WarrantyItem({
    required this.appliance,
    required this.model,
    required this.status,
    required this.expiry,
    required this.expiryDate,
    required this.applianceType,
    required this.icon,
  });
}

class _WarrantyFilterSelection {
  final _WarrantyFilter status;
  final _ExpiryPeriod expiryPeriod;
  final _ApplianceType applianceType;
  final _WarrantySort sort;

  const _WarrantyFilterSelection({
    required this.status,
    required this.expiryPeriod,
    required this.applianceType,
    required this.sort,
  });
}

class WarrantiesScreen extends StatefulWidget {
  const WarrantiesScreen({super.key});

  @override
  State<WarrantiesScreen> createState() => _WarrantiesScreenState();
}

class _WarrantiesScreenState extends State<WarrantiesScreen> {
  static final _mockWarranties = [
    _WarrantyItem(
      appliance: 'Samsung Refrigerator',
      model: 'RT32K5032S8',
      status: _WarrantyStatus.active,
      expiry: 'Ends 12 Aug 2028',
      expiryDate: DateTime(2028, 8, 12),
      applianceType: _ApplianceType.refrigerator,
      icon: Icons.kitchen_rounded,
    ),
    _WarrantyItem(
      appliance: 'LG Washing Machine',
      model: 'FHT1207SWS',
      status: _WarrantyStatus.expiringSoon,
      expiry: 'Ends 20 Jan 2027',
      expiryDate: DateTime(2027, 1, 20),
      applianceType: _ApplianceType.washingMachine,
      icon: Icons.local_laundry_service_outlined,
    ),
    _WarrantyItem(
      appliance: 'Haier Air Conditioner',
      model: 'HSU-18V-FN',
      status: _WarrantyStatus.active,
      expiry: 'Ends 15 Jun 2028',
      expiryDate: DateTime(2028, 6, 15),
      applianceType: _ApplianceType.airConditioner,
      icon: Icons.ac_unit_rounded,
    ),
    _WarrantyItem(
      appliance: 'Sony LED TV',
      model: 'KD-43X75K',
      status: _WarrantyStatus.expired,
      expiry: 'Ended 10 Mar 2025',
      expiryDate: DateTime(2025, 3, 10),
      applianceType: _ApplianceType.television,
      icon: Icons.tv_rounded,
    ),
  ];

  _WarrantyFilter _selectedFilter = _WarrantyFilter.all;
  _ExpiryPeriod _selectedExpiryPeriod = _ExpiryPeriod.anyTime;
  _ApplianceType _selectedApplianceType = _ApplianceType.all;
  _WarrantySort _selectedSort = _WarrantySort.expiryEarliest;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_WarrantyItem> get _visibleWarranties {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final today = DateUtils.dateOnly(DateTime.now());

    final filteredWarranties = _mockWarranties.where((item) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          item.appliance.toLowerCase().contains(normalizedQuery) ||
          item.model.toLowerCase().contains(normalizedQuery);

      final matchesStatus = switch (_selectedFilter) {
        _WarrantyFilter.all => true,
        _WarrantyFilter.active => item.status == _WarrantyStatus.active,
        _WarrantyFilter.expiring => item.status == _WarrantyStatus.expiringSoon,
        _WarrantyFilter.expired => item.status == _WarrantyStatus.expired,
      };

      final matchesApplianceType =
          _selectedApplianceType == _ApplianceType.all ||
          item.applianceType == _selectedApplianceType;

      final daysUntilExpiry = item.expiryDate.difference(today).inDays;
      final matchesExpiryPeriod = switch (_selectedExpiryPeriod) {
        _ExpiryPeriod.anyTime => true,
        _ExpiryPeriod.within30Days =>
          daysUntilExpiry >= 0 && daysUntilExpiry <= 30,
        _ExpiryPeriod.within3Months =>
          daysUntilExpiry >= 0 && daysUntilExpiry <= 92,
        _ExpiryPeriod.within6Months =>
          daysUntilExpiry >= 0 && daysUntilExpiry <= 183,
      };

      return matchesSearch &&
          matchesStatus &&
          matchesApplianceType &&
          matchesExpiryPeriod;
    }).toList();

    filteredWarranties.sort((first, second) {
      final comparison = first.expiryDate.compareTo(second.expiryDate);
      return _selectedSort == _WarrantySort.expiryEarliest
          ? comparison
          : -comparison;
    });

    return filteredWarranties;
  }

  bool get _hasAdvancedFilters =>
      _selectedFilter != _WarrantyFilter.all ||
      _selectedExpiryPeriod != _ExpiryPeriod.anyTime ||
      _selectedApplianceType != _ApplianceType.all ||
      _selectedSort != _WarrantySort.expiryEarliest;

  Future<void> _showFilterSheet() async {
    final selection = await showModalBottomSheet<_WarrantyFilterSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _WarrantyFilterSheet(
          initialSelection: _WarrantyFilterSelection(
            status: _selectedFilter,
            expiryPeriod: _selectedExpiryPeriod,
            applianceType: _selectedApplianceType,
            sort: _selectedSort,
          ),
        );
      },
    );

    if (selection == null || !mounted) return;

    setState(() {
      _selectedFilter = selection.status;
      _selectedExpiryPeriod = selection.expiryPeriod;
      _selectedApplianceType = selection.applianceType;
      _selectedSort = selection.sort;
    });
  }

  void _showComingSoonMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final visibleWarranties = _visibleWarranties;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: AppConstants.paddingMedium,
        title: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: AppColors.primaryBlue),
            SizedBox(width: 10),
            Text('Warranties'),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingMedium,
            AppConstants.paddingMedium,
            AppConstants.paddingMedium,
            AppConstants.paddingLarge,
          ),
          children: [
            _WarrantySearchBar(
              controller: _searchController,
              hasActiveFilters: _hasAdvancedFilters,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              onFilterPressed: _showFilterSheet,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            _ExpiryAlertCard(
              onTap: () {
                setState(() => _selectedFilter = _WarrantyFilter.expiring);
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _WarrantyFilterChip(
                    label: 'All (5)',
                    isSelected: _selectedFilter == _WarrantyFilter.all,
                    onSelected: () {
                      setState(() => _selectedFilter = _WarrantyFilter.all);
                    },
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  _WarrantyFilterChip(
                    label: 'Active (3)',
                    isSelected: _selectedFilter == _WarrantyFilter.active,
                    onSelected: () {
                      setState(() => _selectedFilter = _WarrantyFilter.active);
                    },
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  _WarrantyFilterChip(
                    label: 'Expiring (1)',
                    isSelected: _selectedFilter == _WarrantyFilter.expiring,
                    onSelected: () {
                      setState(
                        () => _selectedFilter = _WarrantyFilter.expiring,
                      );
                    },
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  _WarrantyFilterChip(
                    label: 'Expired (1)',
                    isSelected: _selectedFilter == _WarrantyFilter.expired,
                    onSelected: () {
                      setState(() => _selectedFilter = _WarrantyFilter.expired);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            if (_mockWarranties.isEmpty)
              _EmptyWarrantyState(
                onAddWarranty: () {
                  context.push('/add-warranty');
                },
              )
            else if (visibleWarranties.isEmpty)
              const _NoWarrantyResults()
            else
              for (
                var index = 0;
                index < visibleWarranties.length;
                index++
              ) ...[
                _WarrantyCard(
                  warranty: visibleWarranties[index],
                  onTap: () {
                    _showComingSoonMessage(
                      'Warranty details will be available soon.',
                    );
                  },
                ),
                if (index != visibleWarranties.length - 1)
                  const SizedBox(height: 12),
              ],
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/add-warranty');
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Warranty'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarrantySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterPressed;
  final bool hasActiveFilters;

  const _WarrantySearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilterPressed,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search appliances...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClear,
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                    ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingSmall),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: hasActiveFilters
                  ? AppColors.primaryBlue
                  : const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
              child: IconButton(
                onPressed: onFilterPressed,
                tooltip: 'Filter warranties',
                color: hasActiveFilters
                    ? AppColors.surface
                    : AppColors.primaryBlue,
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
            if (hasActiveFilters)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ExpiryAlertCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ExpiryAlertCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFED7AA)),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDD5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3 Warranties Expiring Soon',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF9A3412),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View expiry details',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFC2410C),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC2410C)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarrantyFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _WarrantyFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? AppColors.primaryBlue : AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected ? AppColors.surface : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _WarrantyCard extends StatelessWidget {
  final _WarrantyItem warranty;
  final VoidCallback onTap;

  const _WarrantyCard({required this.warranty, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 66,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                ),
                child: Icon(
                  warranty.icon,
                  size: 32,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            warranty.appliance,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        _WarrantyStatusBadge(status: warranty.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      warranty.model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      warranty.expiry,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarrantyStatusBadge extends StatelessWidget {
  final _WarrantyStatus status;

  const _WarrantyStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, backgroundColor) = switch (status) {
      _WarrantyStatus.active => (
        'Active',
        AppColors.success,
        const Color(0xFFDCFCE7),
      ),
      _WarrantyStatus.expiringSoon => (
        'Expiring Soon',
        const Color(0xFFEA580C),
        const Color(0xFFFFEDD5),
      ),
      _WarrantyStatus.expired => (
        'Expired',
        AppColors.error,
        const Color(0xFFFEE2E2),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyFilterSheet extends StatefulWidget {
  final _WarrantyFilterSelection initialSelection;

  const _WarrantyFilterSheet({required this.initialSelection});

  @override
  State<_WarrantyFilterSheet> createState() => _WarrantyFilterSheetState();
}

class _WarrantyFilterSheetState extends State<_WarrantyFilterSheet> {
  late _WarrantyFilter _status;
  late _ExpiryPeriod _expiryPeriod;
  late _ApplianceType _applianceType;
  late _WarrantySort _sort;

  @override
  void initState() {
    super.initState();
    _status = widget.initialSelection.status;
    _expiryPeriod = widget.initialSelection.expiryPeriod;
    _applianceType = widget.initialSelection.applianceType;
    _sort = widget.initialSelection.sort;
  }

  void _resetFilters() {
    setState(() {
      _status = _WarrantyFilter.all;
      _expiryPeriod = _ExpiryPeriod.anyTime;
      _applianceType = _ApplianceType.all;
      _sort = _WarrantySort.expiryEarliest;
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop(
      _WarrantyFilterSelection(
        status: _status,
        expiryPeriod: _expiryPeriod,
        applianceType: _applianceType,
        sort: _sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingLarge,
              12,
              AppConstants.paddingMedium,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter Warranties',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close filters',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              children: [
                _FilterSection<_WarrantyFilter>(
                  title: 'Warranty Status',
                  selectedValue: _status,
                  options: const [
                    (_WarrantyFilter.all, 'All'),
                    (_WarrantyFilter.active, 'Active'),
                    (_WarrantyFilter.expiring, 'Expiring Soon'),
                    (_WarrantyFilter.expired, 'Expired'),
                  ],
                  onSelected: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                _FilterSection<_ExpiryPeriod>(
                  title: 'Expiry Period',
                  selectedValue: _expiryPeriod,
                  options: const [
                    (_ExpiryPeriod.anyTime, 'Any time'),
                    (_ExpiryPeriod.within30Days, 'Within 30 days'),
                    (_ExpiryPeriod.within3Months, 'Within 3 months'),
                    (_ExpiryPeriod.within6Months, 'Within 6 months'),
                  ],
                  onSelected: (value) {
                    setState(() => _expiryPeriod = value);
                  },
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                _FilterSection<_ApplianceType>(
                  title: 'Appliance Type',
                  selectedValue: _applianceType,
                  options: const [
                    (_ApplianceType.all, 'All appliances'),
                    (_ApplianceType.refrigerator, 'Refrigerator'),
                    (_ApplianceType.washingMachine, 'Washing Machine'),
                    (_ApplianceType.airConditioner, 'Air Conditioner'),
                    (_ApplianceType.television, 'TV'),
                  ],
                  onSelected: (value) {
                    setState(() => _applianceType = value);
                  },
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                _FilterSection<_WarrantySort>(
                  title: 'Sort By',
                  selectedValue: _sort,
                  options: const [
                    (
                      _WarrantySort.expiryEarliest,
                      'Expiry date: Earliest first',
                    ),
                    (_WarrantySort.expiryLatest, 'Expiry date: Latest first'),
                  ],
                  onSelected: (value) => setState(() => _sort = value),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingLarge,
              12,
              AppConstants.paddingLarge,
              AppConstants.paddingMedium,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset Filters'),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection<T> extends StatelessWidget {
  final String title;
  final T selectedValue;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;

  const _FilterSection({
    required this.title,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        for (final option in options) ...[
          _FilterOption(
            label: option.$2,
            isSelected: selectedValue == option.$1,
            onTap: () => onSelected(option.$1),
          ),
          if (option != options.last) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? const Color(0xFFEFF6FF) : AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoWarrantyResults extends StatelessWidget {
  const _NoWarrantyResults();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: 36,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 52,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text('No warranties found', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Try a different search or adjust your filters.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWarrantyState extends StatelessWidget {
  final VoidCallback onAddWarranty;

  const _EmptyWarrantyState({required this.onAddWarranty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: 36,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 52,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text('No warranties yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Add warranty information to keep track of coverage and expiry dates.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton.icon(
              onPressed: onAddWarranty,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Warranty'),
            ),
          ],
        ),
      ),
    );
  }
}
