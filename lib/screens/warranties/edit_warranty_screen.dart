import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';

enum _EditWarrantyTab { details, documents }

class EditWarrantyScreen extends StatefulWidget {
  const EditWarrantyScreen({super.key});

  @override
  State<EditWarrantyScreen> createState() => _EditWarrantyScreenState();
}

class _EditWarrantyScreenState extends State<EditWarrantyScreen> {
  static const _applianceTypes = [
    'Refrigerator',
    'Washing Machine',
    'Air Conditioner',
    'TV',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController(text: 'Samsung');
  final _modelController = TextEditingController(text: 'RT32K5032S8');
  final _startDateController = TextEditingController(text: '12 Aug 2026');
  final _endDateController = TextEditingController(text: '12 Aug 2028');
  final _providerController = TextEditingController(text: 'Samsung Sri Lanka');
  final _notesController = TextEditingController(
    text: 'Standard manufacturer warranty.',
  );

  _EditWarrantyTab _selectedTab = _EditWarrantyTab.details;
  String? _applianceType = 'Refrigerator';
  DateTime? _startDate = DateTime(2026, 8, 12);
  DateTime? _endDate = DateTime(2028, 8, 12);
  bool _validationAttempted = false;
  bool _isSelectingFile = false;
  PlatformFile? _replacementFile;
  Uint8List? _replacementImageBytes;
  int? _replacementFileSize;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _providerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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

  void _revalidate() {
    if (_validationAttempted) _formKey.currentState?.validate();
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate ?? DateTime.now()
          : _endDate ?? _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStartDate
          ? 'Select warranty start date'
          : 'Select warranty end date',
    );
    if (selected == null || !mounted) return;

    setState(() {
      if (isStartDate) {
        _startDate = selected;
        _startDateController.text = _formatDate(selected);
      } else {
        _endDate = selected;
        _endDateController.text = _formatDate(selected);
      }
    });
    _revalidate();
  }

  String? _requiredText(String? value, String field) {
    if (value == null || value.trim().isEmpty) return 'Please enter $field.';
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _saveDetails() {
    FocusScope.of(context).unfocus();
    setState(() => _validationAttempted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _showMessage('Warranty changes saved locally for preview.');
  }

  void _saveDocuments() {
    FocusScope.of(context).unfocus();
    if (_replacementFile == null) {
      _showMessage('No replacement document selected.');
      return;
    }
    _showMessage('Document changes saved locally for preview.');
  }

  String get _replacementExtension {
    final name = _replacementFile?.name ?? '';
    final index = name.lastIndexOf('.');
    return index < 0 ? '' : name.substring(index + 1).toLowerCase();
  }

  bool get _replacementIsImage =>
      const ['jpg', 'jpeg', 'png'].contains(_replacementExtension);

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Size unavailable';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _chooseReplacement() async {
    if (_isSelectingFile) return;
    setState(() => _isSelectingFile = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (file == null || !mounted) return;

      final size = file.lengthSync() ?? await file.length();
      if (size != null && size > 10 * 1024 * 1024) {
        _showMessage('Please select a file smaller than 10 MB.');
        return;
      }
      final lowerName = file.name.toLowerCase();
      final isImage =
          lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg') ||
          lowerName.endsWith('.png');
      final imageBytes = isImage ? await file.readAsBytes() : null;
      if (!mounted) return;

      setState(() {
        _replacementFile = file;
        _replacementFileSize = size;
        _replacementImageBytes = imageBytes;
      });
    } catch (_) {
      if (mounted) _showMessage('Unable to open the selected file.');
    } finally {
      if (mounted) setState(() => _isSelectingFile = false);
    }
  }

  void _clearReplacement() {
    setState(() {
      _replacementFile = null;
      _replacementFileSize = null;
      _replacementImageBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Load selected warranty data during backend integration.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back to warranty details',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Edit Warranty'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingMedium,
                  AppConstants.paddingSmall,
                  AppConstants.paddingMedium,
                  AppConstants.paddingLarge,
                ),
                child: Column(
                  children: [
                    const _EditSummaryCard(),
                    const SizedBox(height: AppConstants.paddingMedium),
                    _EditTabs(
                      selectedTab: _selectedTab,
                      onSelected: (tab) => setState(() => _selectedTab = tab),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    if (_selectedTab == _EditWarrantyTab.details)
                      _buildDetailsForm()
                    else
                      _buildDocumentsEditor(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: ElevatedButton(
                onPressed: _selectedTab == _EditWarrantyTab.details
                    ? _saveDetails
                    : _saveDocuments,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsForm() {
    return Form(
      key: _formKey,
      autovalidateMode: _validationAttempted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Warranty Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _EditField(
            icon: Icons.kitchen_outlined,
            label: 'Appliance Type',
            isRequired: true,
            child: DropdownButtonFormField<String>(
              initialValue: _applianceType,
              isExpanded: true,
              items: _applianceTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _applianceType = value);
                _revalidate();
              },
              validator: (value) =>
                  value == null ? 'Please select an appliance type.' : null,
            ),
          ),
          _EditField(
            icon: Icons.sell_outlined,
            label: 'Brand',
            isRequired: true,
            child: TextFormField(
              controller: _brandController,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _revalidate(),
              validator: (value) => _requiredText(value, 'brand'),
            ),
          ),
          _EditField(
            icon: Icons.inventory_2_outlined,
            label: 'Model',
            isRequired: true,
            child: TextFormField(
              controller: _modelController,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _revalidate(),
              validator: (value) => _requiredText(value, 'model'),
            ),
          ),
          _EditField(
            icon: Icons.calendar_today_outlined,
            label: 'Warranty Start Date',
            isRequired: true,
            child: TextFormField(
              controller: _startDateController,
              readOnly: true,
              onTap: () => _pickDate(isStartDate: true),
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (_) {
                if (_startDate == null) {
                  return 'Please select a warranty start date.';
                }
                if (_endDate != null && _endDate!.isBefore(_startDate!)) {
                  return 'Start date cannot be later than end date.';
                }
                return null;
              },
            ),
          ),
          _EditField(
            icon: Icons.event_available_outlined,
            label: 'Warranty End Date',
            isRequired: true,
            child: TextFormField(
              controller: _endDateController,
              readOnly: true,
              onTap: () => _pickDate(isStartDate: false),
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (_) {
                if (_endDate == null) {
                  return 'Please select a warranty end date.';
                }
                if (_startDate != null && _endDate!.isBefore(_startDate!)) {
                  return 'End date cannot be earlier than start date.';
                }
                return null;
              },
            ),
          ),
          _EditField(
            icon: Icons.business_outlined,
            label: 'Provider / Company',
            child: TextFormField(
              controller: _providerController,
              textInputAction: TextInputAction.next,
            ),
          ),
          _EditField(
            icon: Icons.description_outlined,
            label: 'Notes',
            child: TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Document',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _CurrentDocumentCard(onReplace: _chooseReplacement),
        const SizedBox(height: AppConstants.paddingLarge),
        _ReplacementArea(
          isSelecting: _isSelectingFile,
          onTap: _chooseReplacement,
        ),
        if (_replacementFile != null) ...[
          const SizedBox(height: AppConstants.paddingMedium),
          _ReplacementFileCard(
            file: _replacementFile!,
            imageBytes: _replacementImageBytes,
            isImage: _replacementIsImage,
            size: _formatFileSize(_replacementFileSize),
            onRemove: _clearReplacement,
            onChange: _chooseReplacement,
          ),
        ],
        const SizedBox(height: AppConstants.paddingMedium),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_rounded, color: AppColors.primaryBlue, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your selected replacement will be applied when document storage integration is completed.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditSummaryCard extends StatelessWidget {
  const _EditSummaryCard();

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
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.kitchen_rounded,
                size: 54,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
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
                  Text('RT32K5032S8', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: AppColors.success,
                        ),
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
                  ),
                  const SizedBox(height: 8),
                  Text('Ends 12 Aug 2028', style: theme.textTheme.bodyMedium),
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

class _EditTabs extends StatelessWidget {
  final _EditWarrantyTab selectedTab;
  final ValueChanged<_EditWarrantyTab> onSelected;

  const _EditTabs({required this.selectedTab, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tab in _EditWarrantyTab.values)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(tab),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selectedTab == tab
                          ? AppColors.primaryBlue
                          : AppColors.border,
                      width: selectedTab == tab ? 3 : 1,
                    ),
                  ),
                ),
                child: Text(
                  tab == _EditWarrantyTab.details ? 'Details' : 'Documents (1)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selectedTab == tab
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary,
                    fontWeight: selectedTab == tab
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isRequired;
  final Widget child;

  const _EditField({
    required this.icon,
    required this.label,
    required this.child,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 26),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    children: isRequired
                        ? const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ]
                        : const [],
                  ),
                ),
                const SizedBox(height: 5),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentDocumentCard extends StatelessWidget {
  final VoidCallback onReplace;

  const _CurrentDocumentCard({required this.onReplace});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.error,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Warranty_Certificate.pdf',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Warranty Certificate',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Added on 12 Aug 2026',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Document options',
              onSelected: (_) => onReplace(),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'replace',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.upload_file_outlined),
                    title: Text('Replace document'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplacementArea extends StatelessWidget {
  final bool isSelecting;
  final VoidCallback onTap;

  const _ReplacementArea({required this.isSelecting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FBFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isSelecting ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF93C5FD)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                isSelecting
                    ? Icons.hourglass_top_rounded
                    : Icons.cloud_upload_outlined,
                color: AppColors.primaryBlue,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                isSelecting ? 'Opening files...' : 'Replace Document',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to select a new document',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 3),
              Text(
                'PDF, JPG, PNG (Max 10MB)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplacementFileCard extends StatelessWidget {
  final PlatformFile file;
  final Uint8List? imageBytes;
  final bool isImage;
  final String size;
  final VoidCallback onRemove;
  final VoidCallback onChange;

  const _ReplacementFileCard({
    required this.file,
    required this.imageBytes,
    required this.isImage,
    required this.size,
    required this.onRemove,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 60,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isImage && imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : const Icon(
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
                    file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('${file.extension?.toUpperCase() ?? 'FILE'} · $size'),
                  TextButton(onPressed: onChange, child: const Text('Change')),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: 'Clear replacement',
              color: AppColors.error,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
