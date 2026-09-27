import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'maintenance_models.dart';

enum MaintenanceFormMode { add, complete }

class MaintenanceFormScreen extends StatefulWidget {
  final MaintenanceFormMode mode;
  final MaintenanceRecord? record;
  const MaintenanceFormScreen({super.key, required this.mode, this.record});

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notesController;
  late final TextEditingController _costController;
  late final TextEditingController _providerController;
  String? _appliance;
  String? _type;
  DateTime? _date;
  final List<String> _photos = [];

  bool get isCompleting => widget.mode == MaintenanceFormMode.complete;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _notesController = TextEditingController(text: record?.notes);
    _costController = TextEditingController(text: record?.cost);
    _providerController = TextEditingController(text: record?.serviceProvider);
    _date = isCompleting ? DateTime.now() : record?.scheduledDate;
    _appliance = record?.appliance;
    _type = record?.title;
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
    final result = await FilePicker.pickFiles(type: FileType.image);
    setState(() => _photos.addAll(result.map((file) => file.name)));
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _date == null) {
      setState(() {});
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCompleting
              ? 'Maintenance marked as completed.'
              : 'Maintenance record saved.',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCompleting ? 'Mark as Completed' : 'Add Maintenance Record',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            if (isCompleting) ...[
              _SelectedRecordCard(
                record: widget.record ?? maintenanceRecords.first,
              ),
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
            _FieldLabel(label: 'Notes', requiredField: !isCompleting),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              validator: isCompleting
                  ? null
                  : (value) => value == null || value.trim().isEmpty
                        ? 'Please add notes'
                        : null,
              decoration: InputDecoration(
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
            _PhotoPicker(photos: _photos, onTap: _selectPhotos),
            const SizedBox(height: 24),
            PrimaryButton(
              text: isCompleting ? 'Mark as Completed' : 'Save Record',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
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
  final List<String> photos;
  final VoidCallback onTap;
  const _PhotoPicker({required this.photos, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final content = photos.isEmpty
        ? const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.textSecondary,
                size: 28,
              ),
              SizedBox(height: 8),
              Text(
                'Tap to add photos',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: photos
                  .map(
                    (photo) => Chip(
                      avatar: const Icon(Icons.image_outlined, size: 16),
                      label: Text(photo, overflow: TextOverflow.ellipsis),
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
