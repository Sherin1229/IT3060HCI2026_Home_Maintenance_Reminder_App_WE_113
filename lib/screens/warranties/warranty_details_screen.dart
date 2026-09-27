import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';

enum _WarrantyDetailsTab { details, documents }

enum _WarrantyMenuAction { edit, delete }

class WarrantyDetailsScreen extends StatefulWidget {
  const WarrantyDetailsScreen({super.key});

  @override
  State<WarrantyDetailsScreen> createState() => _WarrantyDetailsScreenState();
}

class _WarrantyDetailsScreenState extends State<WarrantyDetailsScreen> {
  _WarrantyDetailsTab _selectedTab = _WarrantyDetailsTab.details;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openEditWarranty() => context.push('/warranties/edit');

  Future<void> _showDeleteConfirmation() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE4E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 38,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  'Delete Warranty?',
                  style: Theme.of(dialogContext).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete this warranty record? This action cannot be undone.',
                  style: Theme.of(dialogContext).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.surface,
                    ),
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (shouldDelete == true && mounted) {
      // TODO: During backend integration, delete the selected warranty,
      // return to the Warranty List, and show deletion success feedback.
      _showMessage('Delete functionality will be connected later.');
    }
  }

  void _handleMenuAction(_WarrantyMenuAction action) {
    switch (action) {
      case _WarrantyMenuAction.edit:
        _openEditWarranty();
        return;
      case _WarrantyMenuAction.delete:
        _showDeleteConfirmation();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back to warranties',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Warranty Details'),
        centerTitle: true,
        actions: [
          PopupMenuButton<_WarrantyMenuAction>(
            tooltip: 'Warranty options',
            onSelected: _handleMenuAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _WarrantyMenuAction.edit,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: _WarrantyMenuAction.delete,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingMedium,
                  AppConstants.paddingSmall,
                  AppConstants.paddingMedium,
                  AppConstants.paddingLarge,
                ),
                child: Column(
                  children: [
                    const _WarrantySummaryCard(),
                    const SizedBox(height: AppConstants.paddingMedium),
                    _WarrantyTabs(
                      selectedTab: _selectedTab,
                      onSelected: (tab) {
                        setState(() => _selectedTab = tab);
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _selectedTab == _WarrantyDetailsTab.details
                          ? const _DetailsCard(
                              key: ValueKey('warranty-details'),
                            )
                          : _DocumentsCard(
                              key: const ValueKey('warranty-documents'),
                              onPreview: () => _showMessage(
                                'Document preview will be available after storage integration.',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            _BottomActions(
              onEdit: _openEditWarranty,
              onDelete: _showDeleteConfirmation,
            ),
          ],
        ),
      ),
    );
  }
}

class _WarrantySummaryCard extends StatelessWidget {
  const _WarrantySummaryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 82,
              height: 104,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              child: const Icon(
                Icons.kitchen_rounded,
                size: 54,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Samsung Refrigerator',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('RT32K5032S8', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 9),
                  const _ActiveBadge(),
                  const SizedBox(height: 9),
                  Text(
                    'Ends 12 Aug 2028',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '2 years remaining',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
          SizedBox(width: 4),
          Text(
            'Active',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyTabs extends StatelessWidget {
  final _WarrantyDetailsTab selectedTab;
  final ValueChanged<_WarrantyDetailsTab> onSelected;

  const _WarrantyTabs({required this.selectedTab, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Details',
            isSelected: selectedTab == _WarrantyDetailsTab.details,
            onTap: () => onSelected(_WarrantyDetailsTab.details),
          ),
        ),
        Expanded(
          child: _TabButton(
            label: 'Documents (1)',
            isSelected: selectedTab == _WarrantyDetailsTab.documents,
            onTap: () => onSelected(_WarrantyDetailsTab.documents),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryBlue : AppColors.border,
              width: isSelected ? 3 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({super.key});

  static const _items = [
    (Icons.kitchen_outlined, 'Appliance Type', 'Refrigerator'),
    (Icons.sell_outlined, 'Brand', 'Samsung'),
    (Icons.inventory_2_outlined, 'Model', 'RT32K5032S8'),
    (Icons.calendar_today_outlined, 'Warranty Start Date', '12 Aug 2026'),
    (Icons.event_available_outlined, 'Warranty End Date', '12 Aug 2028'),
    (Icons.business_outlined, 'Provider / Company', 'Samsung Sri Lanka'),
    (Icons.description_outlined, 'Notes', 'Standard manufacturer warranty.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: 6,
        ),
        child: Column(
          children: [
            for (var index = 0; index < _items.length; index++) ...[
              _DetailRow(
                icon: _items[index].$1,
                label: _items[index].$2,
                value: _items[index].$3,
              ),
              if (index != _items.length - 1)
                const Divider(height: 1, indent: 52),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusSmall,
              ),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
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

class _DocumentsCard extends StatelessWidget {
  final VoidCallback onPreview;

  const _DocumentsCard({super.key, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Warranty_Certificate.pdf',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Warranty Certificate · PDF',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onPreview,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 19),
                    label: const Text('View Preview'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BottomActions({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMedium,
        12,
        AppConstants.paddingMedium,
        AppConstants.paddingMedium,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Edit'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}
