import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/maintenance_model.dart';
import '../../providers/maintenance_provider.dart';
import '../../widgets/primary_button.dart';

class MaintenanceFormScreen extends StatefulWidget {
  final MaintenanceFormMode mode;
  final String? recordId;
  const MaintenanceFormScreen({super.key, required this.mode, this.recordId});

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

enum MaintenanceFormMode { add, edit, complete }

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _costController = TextEditingController();
  final _providerController = TextEditingController();
  String? _appliance;
  String? _type;
  DateTime? _date;
  MaintenanceRecord? _record;
  List<PlatformFile> _selectedFiles = [];
  bool _loadingRecord = false;
  bool _submitting = false;

  bool get isCompleting => widget.mode == MaintenanceFormMode.complete;
  bool get isEditing => widget.mode == MaintenanceFormMode.edit;

  @override
  void initState() {
    super.initState();
    if (widget.recordId != null) {
      _loadingRecord = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecord());
    }
  }

  Future<void> _loadRecord() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.recordId == null) {
      if (mounted) setState(() => _loadingRecord = false);
      return;
    }
    MaintenanceRecord? record;
    try {
      record = await context.read<MaintenanceProvider>().getRecordOnce(
        widget.recordId!,
        user.uid,
      );
    } catch (error) {
      debugPrint('Maintenance record load error: $error');
    }
    if (!mounted) return;
    if (record != null) {
      _record = record;
      _appliance = record.appliance;
      _type = record.title;
      _date = isCompleting ? DateTime.now() : record.scheduledDate;
      _notesController.text = record.notes ?? '';
      _costController.text = record.cost ?? '';
      _providerController.text = record.serviceProvider ?? '';
    }
    setState(() => _loadingRecord = false);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _costController.dispose();
    _providerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _selectPhotos() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (mounted) setState(() => _selectedFiles = [..._selectedFiles, ...files]);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false) || _date == null) {
      setState(() {});
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please log in before saving a maintenance record.');
      return;
    }
    if ((isEditing || isCompleting) && _record == null) {
      _showMessage('Maintenance record information is unavailable.');
      return;
    }
    final maintenanceProvider = context.read<MaintenanceProvider>();
    setState(() => _submitting = true);
    try {
      final bytes = <Uint8List>[];
      for (final file in _selectedFiles) {
        bytes.add(await file.readAsBytes());
      }
      final uploadedUrls = _selectedFiles.isEmpty
          ? <String>[]
          : await maintenanceProvider.uploadPhotos(
              bytes,
              _selectedFiles.map((file) => file.name).toList(),
            );
      if (_selectedFiles.isNotEmpty && uploadedUrls == null) {
        throw StateError('Photo upload failed.');
      }
      final existingUrls = _record?.photoUrls ?? const <String>[];
      final photoUrls = [...existingUrls, ...?uploadedUrls];
      final success = isCompleting
          ? await maintenanceProvider.markCompleted(
              recordId: _record!.id,
              completedDate: _date!,
              notes: _optionalValue(_notesController.text),
              cost: _optionalValue(_costController.text),
              serviceProvider: _optionalValue(_providerController.text),
              photoUrls: photoUrls,
            )
          : isEditing
          ? await maintenanceProvider.updateRecord(
              MaintenanceRecord(
                id: _record!.id,
                userId: _record!.userId,
                title: _type!.trim(),
                appliance: _appliance!.trim(),
                location: _record!.location.isEmpty
                    ? _appliance!.trim()
                    : _record!.location,
                scheduledDate: _date!,
                completedDate: _record!.completedDate,
                cost: _optionalValue(_costController.text),
                serviceProvider: _optionalValue(_providerController.text),
                notes: _optionalValue(_notesController.text),
                photoUrls: photoUrls,
                createdAt: _record!.createdAt,
                updatedAt: _record!.updatedAt,
              ),
            )
          : await maintenanceProvider.createRecord(
              MaintenanceRecord(
                id: '',
                userId: user.uid,
                title: _type!.trim(),
                appliance: _appliance!.trim(),
                location: _appliance!.trim(),
                scheduledDate: _date!,
                cost: _optionalValue(_costController.text),
                serviceProvider: _optionalValue(_providerController.text),
                notes: _optionalValue(_notesController.text),
                photoUrls: photoUrls,
                createdAt: DateTime.now(),
              ),
            );
      if (!mounted) return;
      if (!success) {
        _showMessage(
          maintenanceProvider.errorMessage ??
              'Unable to save maintenance record.',
        );
        return;
      }
      _showMessage(
        isCompleting
            ? 'Maintenance marked as completed.'
            : isEditing
            ? 'Maintenance record updated.'
            : 'Maintenance record saved.',
      );
      context.pop();
    } catch (error) {
      debugPrint('Maintenance form error: $error');
      if (mounted) {
        _showMessage('Unable to save maintenance record. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    if (_loadingRecord) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if ((isEditing || isCompleting) && _record == null) {
      return const Scaffold(
        body: Center(
          child: Text('Maintenance record information is unavailable.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            if (isCompleting) ...[
              _SelectedRecordCard(record: _record!),
              const SizedBox(height: 20),
            ],
            if (!isCompleting) ...[
              _FieldLabel(label: 'Appliance', requiredField: true),
              DropdownButtonFormField<String>(
                initialValue: _appliance,
                hint: const Text('Select appliance'),
                items:
                    [
                          'Samsung Refrigerator',
                          'Bedroom AC',
                          'Living Room AC',
                          'Washing Machine',
                          'Kitchen',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _appliance = value),
                validator: (value) =>
                    value == null ? 'Please select an appliance' : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel(label: 'Maintenance Type', requiredField: true),
              DropdownButtonFormField<String>(
                initialValue: _type,
                hint: const Text('Select maintenance type'),
                items:
                    [
                          'AC Cleaning',
                          'Cleaning',
                          'Repair',
                          'Water Filter Replacement',
                          'Filter Replacement',
                          'General Service',
                          'Inspection',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _type = value),
                validator: (value) =>
                    value == null ? 'Please select a maintenance type' : null,
              ),
              const SizedBox(height: 16),
            ],
            _FieldLabel(
              label: isCompleting ? 'Completion Date' : 'Date',
              requiredField: true,
            ),
            _DateField(date: _date, onTap: _selectDate),
            if (_date == null)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  'Please select a date',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Notes'),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add details about the maintenance...',
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Cost (Optional)'),
            TextFormField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 5000',
                prefixText: 'LKR ',
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Service Provider (Optional)'),
            TextFormField(
              controller: _providerController,
              decoration: const InputDecoration(hintText: 'e.g. ABC Service'),
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Attach Photos (Optional)'),
            _PhotoPicker(
              files: _selectedFiles,
              existingCount: _record?.photoUrls.length ?? 0,
              onTap: _selectPhotos,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: _buttonLabel,
              onPressed: _submitting ? null : _submit,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }

  String get _title => isCompleting
      ? 'Mark as Completed'
      : isEditing
      ? 'Edit Maintenance Record'
      : 'Add Maintenance Record';
  String get _buttonLabel => isCompleting
      ? 'Mark as Completed'
      : isEditing
      ? 'Update Record'
      : 'Save Record';
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool requiredField;
  const _FieldLabel({required this.label, this.requiredField = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text.rich(
        TextSpan(
          text: label,
          children: [
            if (requiredField)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.error),
              ),
          ],
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;
  const _DateField({required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          date == null ? 'DD / MM / YYYY' : formatMaintenanceDate(date!),
          style: TextStyle(
            color: date == null
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SelectedRecordCard extends StatelessWidget {
  final MaintenanceRecord record;
  const _SelectedRecordCard({required this.record});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(record.icon, color: AppColors.primaryBlue, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  record.appliance,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Scheduled Date  ${formatMaintenanceDate(record.scheduledDate)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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

class _PhotoPicker extends StatelessWidget {
  final List<PlatformFile> files;
  final int existingCount;
  final VoidCallback onTap;
  const _PhotoPicker({
    required this.files,
    required this.existingCount,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final content = files.isEmpty
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                existingCount == 0
                    ? 'Tap to add photos'
                    : '$existingCount existing photo(s) · Tap to add more',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: files
                  .map(
                    (file) => Chip(
                      avatar: const Icon(Icons.image_outlined, size: 16),
                      label: Text(file.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
            ),
          );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 104),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      ),
    );
  }
}
