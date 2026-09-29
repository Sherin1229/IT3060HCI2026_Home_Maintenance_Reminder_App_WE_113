import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_colors.dart';
import '../../services/warranty_service.dart';
import '../../utils/constants.dart';

enum _WarrantyDetailsTab { details, documents }

enum _WarrantyMenuAction { edit, delete }

class WarrantyDetailsScreen extends StatefulWidget {
  final String warrantyId;
  
  const WarrantyDetailsScreen({super.key, required this.warrantyId});

  @override
  State<WarrantyDetailsScreen> createState() => _WarrantyDetailsScreenState();
}

class _WarrantyDetailsScreenState extends State<WarrantyDetailsScreen> {
  final WarrantyService _warrantyService = WarrantyService();
  _WarrantyDetailsTab _selectedTab = _WarrantyDetailsTab.details;

  String _getText(dynamic value) {
    if (value == null) return 'Not available';

    final text = value.toString().trim();
    return text.isEmpty ? 'Not available' : text;
  }

  DateTime? _getDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';

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

  String _getWarrantyStatus(DateTime? endDate) {
    if (endDate == null) return 'Not available';

    final today = DateUtils.dateOnly(DateTime.now());
    final expiryDate = DateUtils.dateOnly(endDate);
    final daysUntilExpiry = expiryDate.difference(today).inDays;

    if (daysUntilExpiry < 0) {
      return 'Expired';
    } else if (daysUntilExpiry <= 30) {
      return 'Expiring Soon';
    } else {
      return 'Active';
    }
  }

  String _getExpiryText(DateTime? endDate) {
    if (endDate == null) return 'End date not available';

    final today = DateUtils.dateOnly(DateTime.now());
    final expiryDate = DateUtils.dateOnly(endDate);
    final daysUntilExpiry = expiryDate.difference(today).inDays;

    if (daysUntilExpiry < 0) {
      return 'Ended ${_formatDate(endDate)}';
    }

    return 'Ends ${_formatDate(endDate)}';
  }

  String _getRemainingText(DateTime? endDate) {
    if (endDate == null) return 'Remaining time unavailable';

    final today = DateUtils.dateOnly(DateTime.now());
    final expiryDate = DateUtils.dateOnly(endDate);
    final days = expiryDate.difference(today).inDays;

    if (days < 0) {
      final expiredDays = -days;

      if (expiredDays == 1) {
        return 'Expired 1 day ago';
      }

      return 'Expired $expiredDays days ago';
    }

    if (days == 0) return 'Expires today';
    if (days == 1) return '1 day remaining';

    if (days < 60) {
      return '$days days remaining';
    }

    if (days < 730) {
      final months = (days / 30).floor();
      return '$months months remaining';
    }

    final years = (days / 365).floor();
    return years == 1 ? '1 year remaining' : '$years years remaining';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDocumentPreview({
    required String documentUrl,
    required String documentName,
  }) async {
    if (documentUrl.trim().isEmpty) {
      _showMessage('Preview is not available for this document.');
      return;
    }

    final lowerFileName = documentName.toLowerCase();

    final isImage =
        lowerFileName.endsWith('.jpg') ||
        lowerFileName.endsWith('.jpeg') ||
        lowerFileName.endsWith('.png');

    if (isImage) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
                maxHeight: 700,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            documentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(dialogContext)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close preview',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4,
                        child: Image.network(
                          documentUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (
                            context,
                            child,
                            loadingProgress,
                          ) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'Unable to load document preview.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      return;
    }

    final uri = Uri.tryParse(documentUrl);

    if (uri == null) {
      _showMessage('Invalid document link.');
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage('Unable to open this document.');
      }
    } catch (e) {
      debugPrint('Document preview error: $e');

      if (mounted) {
        _showMessage('Unable to open this document.');
      }
    }
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view warranty details.'),
        ),
      );
    }

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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _warrantyService.getWarrantyById(widget.warrantyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load warranty details.'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Warranty not found.'),
            );
          }

          final data = snapshot.data!.data();

          if (data == null) {
            return const Center(
              child: Text('Warranty information is unavailable.'),
            );
          }

          if (data['userId'] != user.uid) {
            return const Center(
              child: Text('You do not have access to this warranty.'),
            );
          }

          final applianceType = _getText(data['applianceType']);
          final brand = _getText(data['brand']);
          final model = _getText(data['model']);
          final provider = _getText(data['provider']);
          final notes = _getText(data['notes']);

          final documentName = _getText(data['documentName']);
          final documentType = _getText(data['documentType']);
          final documentUrl = (data['documentUrl'] as String?)?.trim() ?? '';

          final startDate = _getDate(data['warrantyStartDate']);
          final endDate = _getDate(data['warrantyEndDate']);

          final formattedStartDate = _formatDate(startDate);
          final formattedEndDate = _formatDate(endDate);

          final status = _getWarrantyStatus(endDate);
          final expiryText = _getExpiryText(endDate);
          final remainingText = _getRemainingText(endDate);

          final applianceName = [
            brand,
            applianceType,
          ].where((value) => value != 'Not available').join(' ');

          final summaryTitle =
              applianceName.isEmpty ? 'Warranty' : applianceName;

          return SafeArea(
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
                    _WarrantySummaryCard(
                      appliance: summaryTitle,
                      model: model,
                      status: status,
                      expiryText: expiryText,
                      remainingText: remainingText,
                    ),
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
                          ? _DetailsCard(
                              key: const ValueKey('warranty-details'),
                              applianceType: applianceType,
                              brand: brand,
                              model: model,
                              startDate: formattedStartDate,
                              endDate: formattedEndDate,
                              provider: provider,
                              notes: notes,
                            )
                          : _DocumentsCard(
                              key: const ValueKey('warranty-documents'),
                              documentName: documentName,
                              documentType: documentType,
                              onPreview: () => _openDocumentPreview(
                                documentUrl: documentUrl,
                                documentName: documentName,
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
      );
    },
  ),
);
  }
}

class _WarrantySummaryCard extends StatelessWidget {
  final String appliance;
  final String model;
  final String status;
  final String expiryText;
  final String remainingText;

  const _WarrantySummaryCard({
    required this.appliance,
    required this.model,
    required this.status,
    required this.expiryText,
    required this.remainingText,
  });

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
                    appliance,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(model, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 9),
                  _StatusBadge(status: status),
                  const SizedBox(height: 9),
                  Text(
                    expiryText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    remainingText,
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    late final Color textColor;
    late final Color backgroundColor;
    late final IconData icon;

    switch (status) {
      case 'Expired':
        textColor = AppColors.error;
        backgroundColor = const Color(0xFFFFE4E6);
        icon = Icons.cancel_rounded;
        break;

      case 'Expiring Soon':
        textColor = const Color(0xFFD97706);
        backgroundColor = const Color(0xFFFFF7ED);
        icon = Icons.warning_amber_rounded;
        break;

      case 'Active':
        textColor = AppColors.success;
        backgroundColor = const Color(0xFFDCFCE7);
        icon = Icons.check_circle_rounded;
        break;

      default:
        textColor = AppColors.textSecondary;
        backgroundColor = const Color(0xFFF1F5F9);
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: textColor,
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
  final String applianceType;
  final String brand;
  final String model;
  final String startDate;
  final String endDate;
  final String provider;
  final String notes;

  const _DetailsCard({
    super.key,
    required this.applianceType,
    required this.brand,
    required this.model,
    required this.startDate,
    required this.endDate,
    required this.provider,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.kitchen_outlined, 'Appliance Type', applianceType),
      (Icons.sell_outlined, 'Brand', brand),
      (Icons.inventory_2_outlined, 'Model', model),
      (Icons.calendar_today_outlined, 'Warranty Start Date', startDate),
      (Icons.event_available_outlined, 'Warranty End Date', endDate),
      (Icons.business_outlined, 'Provider / Company', provider),
      (Icons.description_outlined, 'Notes', notes),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: 6,
        ),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _DetailRow(
                icon: items[index].$1,
                label: items[index].$2,
                value: items[index].$3,
              ),
              if (index != items.length - 1)
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
  final String documentName;
  final String documentType;
  final VoidCallback onPreview;

  const _DocumentsCard({super.key, required this.onPreview, required this.documentName, required this.documentType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final lowerFileName = documentName.toLowerCase();
    final isPdf = lowerFileName.endsWith('.pdf');

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
                color: isPdf
                    ? const Color(0xFFFFF1F2)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              child: Icon(
                isPdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
                color: isPdf
                    ? AppColors.error
                    : AppColors.primaryBlue,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    documentName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    documentType,
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
