import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';
import 'add_warranty_screen.dart';

class AddWarrantyDocumentScreen extends StatefulWidget {
  final WarrantyDraft draft;

  const AddWarrantyDocumentScreen({super.key, required this.draft});

  @override
  State<AddWarrantyDocumentScreen> createState() =>
      _AddWarrantyDocumentScreenState();
}

class _AddWarrantyDocumentScreenState extends State<AddWarrantyDocumentScreen> {
  static const _documentTypes = [
    'Warranty Card',
    'Purchase Receipt',
    'Invoice',
    'Service Agreement',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  PlatformFile? _selectedFile;
  Uint8List? _selectedImageBytes;
  int? _selectedFileSize;
  String? _documentType;
  bool _showFileError = false;
  bool _isSelectingFile = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/add-warranty');
    }
  }

  String get _fileExtension {
    final fileName = _selectedFile?.name ?? '';
    final separatorIndex = fileName.lastIndexOf('.');
    if (separatorIndex == -1 || separatorIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(separatorIndex + 1).toLowerCase();
  }

  bool get _isImageFile =>
      const ['jpg', 'jpeg', 'png'].contains(_fileExtension);

  Future<void> _chooseFile() async {
    if (_isSelectingFile) return;

    setState(() => _isSelectingFile = true);

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (file == null || !mounted) return;

      final fileName = file.name.toLowerCase();
      final isImage =
          fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png');
      final imageBytes = isImage ? await file.readAsBytes() : null;
      final fileSize = file.lengthSync() ?? await file.length();

      if (!mounted) return;

      setState(() {
        _selectedFile = file;
        _selectedImageBytes = imageBytes;
        _selectedFileSize = fileSize;
        _showFileError = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to open the selected file.')),
        );
    } finally {
      if (mounted) {
        setState(() => _isSelectingFile = false);
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedImageBytes = null;
      _selectedFileSize = null;
    });
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Size unavailable';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showPreview() {
    final file = _selectedFile;
    if (file == null) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          content: _isImageFile && _selectedImageBytes != null
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: InteractiveViewer(
                    child: Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const _FilePreviewFallback(
                          icon: Icons.broken_image_outlined,
                          message: 'Image preview is unavailable.',
                        );
                      },
                    ),
                  ),
                )
              : _FilePreviewFallback(
                  icon: Icons.picture_as_pdf_outlined,
                  message:
                      'PDF preview is not enabled yet.\n${_formatFileSize(_selectedFileSize)}',
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _saveWarranty() {
    FocusScope.of(context).unfocus();
    final hasFile = _selectedFile != null;

    setState(() => _showFileError = !hasFile);
    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!hasFile || !isFormValid) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Warranty is ready to save.')),
      );
    // TODO: Save widget.draft and the selected document when backend work begins.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          tooltip: 'Back to appliance details',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Add Warranty'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMedium,
              AppConstants.paddingMedium,
              AppConstants.paddingMedium,
              AppConstants.paddingLarge,
            ),
            children: [
              const _DocumentStepIndicator(),
              const SizedBox(height: 28),
              _DocumentUploadArea(
                isSelecting: _isSelectingFile,
                showError: _showFileError,
                onTap: _chooseFile,
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: AppConstants.paddingMedium),
                _SelectedFileCard(
                  fileName: _selectedFile!.name,
                  fileType: _fileExtension.isEmpty
                      ? 'Document'
                      : '${_fileExtension.toUpperCase()} file',
                  fileSize: _formatFileSize(_selectedFileSize),
                  imageBytes: _selectedImageBytes,
                  isImage: _isImageFile,
                  onRemove: _removeFile,
                  onPreview: _showPreview,
                ),
              ],
              const SizedBox(height: AppConstants.paddingLarge),
              _DocumentFormRow(
                icon: Icons.description_outlined,
                label: 'Document Type',
                isRequired: true,
                child: DropdownButtonFormField<String>(
                  initialValue: _documentType,
                  isExpanded: true,
                  hint: const Text('Select document type'),
                  items: _documentTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _documentType = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a document type.' : null,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _DocumentFormRow(
                icon: Icons.notes_rounded,
                label: 'Notes (Optional)',
                alignIconToTop: true,
                child: TextFormField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Add any notes about this document',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveWarranty,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save Warranty'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentStepIndicator extends StatelessWidget {
  const _DocumentStepIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Step 2 of 2, Document Upload. Appliance Details completed.',
      child: Column(
        children: [
          Row(
            children: [
              const _DocumentStepCircle(
                icon: Icons.check_rounded,
                isActive: true,
              ),
              Expanded(
                child: Container(height: 2, color: AppColors.primaryBlue),
              ),
              const _DocumentStepCircle(label: '2', isActive: true),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Appliance Details',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Document Upload',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentStepCircle extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool isActive;

  const _DocumentStepCircle({this.label, this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryBlue : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.primaryBlue : AppColors.border,
          width: 2,
        ),
      ),
      child: icon != null
          ? Icon(icon, color: AppColors.surface, size: 19)
          : Text(
              label ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isActive ? AppColors.surface : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _DocumentUploadArea extends StatelessWidget {
  final bool isSelecting;
  final bool showError;
  final VoidCallback onTap;

  const _DocumentUploadArea({
    required this.isSelecting,
    required this.showError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          child: InkWell(
            onTap: isSelecting ? null : onTap,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
                vertical: 30,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: showError ? AppColors.error : const Color(0xFF93C5FD),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusLarge,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDBEAFE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: AppColors.primaryBlue,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'Tap to upload or take a photo',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text('(PDF, JPG, PNG)', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppConstants.paddingMedium),
                  SizedBox(
                    width: 170,
                    child: ElevatedButton(
                      onPressed: isSelecting ? null : onTap,
                      child: isSelecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surface,
                              ),
                            )
                          : const Text('Choose File'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showError) ...[
          const SizedBox(height: 6),
          Text(
            'Please select a warranty document.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.error,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectedFileCard extends StatelessWidget {
  final String fileName;
  final String fileType;
  final String fileSize;
  final Uint8List? imageBytes;
  final bool isImage;
  final VoidCallback onRemove;
  final VoidCallback onPreview;

  const _SelectedFileCard({
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.imageBytes,
    required this.isImage,
    required this.onRemove,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 82,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              child: isImage && imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.error,
                      size: 36,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$fileType · $fileSize',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View Preview'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: 'Remove selected file',
              color: AppColors.error,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentFormRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isRequired;
  final bool alignIconToTop;
  final Widget child;

  const _DocumentFormRow({
    required this.icon,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.alignIconToTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: alignIconToTop ? 28 : 26),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
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
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _FilePreviewFallback extends StatelessWidget {
  final IconData icon;
  final String message;

  const _FilePreviewFallback({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.primaryBlue),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
