import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';

class _ExpiringWarranty {
  final String appliance;
  final String model;
  final DateTime endDate;
  final String timing;
  final IconData icon;

  const _ExpiringWarranty({
    required this.appliance,
    required this.model,
    required this.endDate,
    required this.timing,
    required this.icon,
  });
}

class WarrantyExpiryScreen extends StatelessWidget {
  const WarrantyExpiryScreen({super.key});

  // TODO: Derive expiring warranties from real warrantyEndDate values during
  // backend integration. Expiring Soon means 0–30 days remaining.
  static final List<_ExpiringWarranty> _warranties = [
    _ExpiringWarranty(
      appliance: 'LG Washing Machine',
      model: 'FHT1207SWS',
      endDate: DateTime(2026, 10, 5),
      timing: '7 days left',
      icon: Icons.local_laundry_service_outlined,
    ),
    _ExpiringWarranty(
      appliance: 'Microwave Oven',
      model: 'MS23K3513AS',
      endDate: DateTime(2026, 10, 16),
      timing: '18 days left',
      icon: Icons.microwave_outlined,
    ),
    _ExpiringWarranty(
      appliance: 'Electric Kettle',
      model: 'HD9316',
      endDate: DateTime(2026, 10, 27),
      timing: '29 days left',
      icon: Icons.coffee_maker_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back to warranties',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Warranty Expiry Information'),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingMedium,
            AppConstants.paddingSmall,
            AppConstants.paddingMedium,
            AppConstants.paddingLarge,
          ),
          children: [
            _ExpirySummaryBanner(count: _warranties.length),
            const SizedBox(height: AppConstants.paddingMedium),
            if (_warranties.isEmpty)
              const _EmptyExpiryState()
            else
              for (var index = 0; index < _warranties.length; index++) ...[
                _ExpiryWarrantyCard(
                  warranty: _warranties[index],
                  onTap: () {
                    // TODO: Pass selected real warranty during backend integration.
                    context.push('/warranties/details');
                  },
                ),
                if (index != _warranties.length - 1) const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _ExpirySummaryBanner extends StatelessWidget {
  final int count;

  const _ExpirySummaryBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Color(0xFFEA580C),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Warranties Expiring Soon',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFC2410C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Take action to avoid losing coverage.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryWarrantyCard extends StatelessWidget {
  final _ExpiringWarranty warranty;
  final VoidCallback onTap;

  const _ExpiryWarrantyCard({required this.warranty, required this.onTap});

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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
            children: [
              Container(
                width: 72,
                height: 82,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                ),
                child: Icon(
                  warranty.icon,
                  color: AppColors.textSecondary,
                  size: 40,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warranty.appliance,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    Text(warranty.model, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        warranty.timing,
                        style: const TextStyle(
                          color: Color(0xFFEA580C),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ends ${_formatDate(warranty.endDate)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryBlue,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyExpiryState extends StatelessWidget {
  const _EmptyExpiryState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            color: AppColors.success,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            'No warranties expiring soon',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Your warranties are currently covered.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
