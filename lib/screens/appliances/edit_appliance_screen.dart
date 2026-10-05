import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/appliance_model.dart';
import '../../providers/appliance_provider.dart';
import '../../utils/constants.dart';

class EditApplianceScreen extends StatefulWidget {
  final String? applianceId;
  final ApplianceModel? appliance;

  const EditApplianceScreen({super.key, this.applianceId, this.appliance});

  @override
  State<EditApplianceScreen> createState() => _EditApplianceScreenState();
}

class _EditApplianceScreenState extends State<EditApplianceScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();

  DateTime? _selectedDate;
  String? _existingPhotoUrl;
  PlatformFile? _newPhotoFile;
  bool _isSubmitting = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.appliance != null) {
      _populateFromAppliance(widget.appliance!);
      _isInitialized = true;
    }
  }

  void _populateFromAppliance(ApplianceModel appliance) {
    _nameController.text = appliance.applianceName;
    _brandController.text = appliance.brand;
    _modelController.text = appliance.modelNumber;
    _serialController.text = appliance.serialNumber ?? '';
    _categoryController.text = appliance.category;
    _selectedDate = appliance.purchaseDate;
    _existingPhotoUrl = appliance.photoUrl;

    final date = appliance.purchaseDate;
    _dateController.text =
        "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _dateController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png'],
      );
      if (result != null) {
        setState(() {
          _newPhotoFile = result;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _submitForm(String targetApplianceId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a purchase date.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to edit appliances.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<ApplianceProvider>();

    try {
      String? finalPhotoUrl = _existingPhotoUrl;

      if (_newPhotoFile != null) {
        final fileBytes = await _newPhotoFile!.readAsBytes();
        final uploadedUrl = await provider.uploadPhoto(
          bytes: fileBytes,
          fileName: _newPhotoFile!.name,
        );
        if (uploadedUrl != null) {
          finalPhotoUrl = uploadedUrl;
        }
      }

      final success = await provider.updateAppliance(
        applianceId: targetApplianceId,
        userId: user.uid,
        applianceName: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        brand: _brandController.text.trim(),
        purchaseDate: _selectedDate!,
        modelNumber: _modelController.text.trim(),
        serialNumber: _serialController.text.trim().isEmpty
            ? null
            : _serialController.text.trim(),
        photoUrl: finalPhotoUrl,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appliance updated successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Failed to update appliance.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating appliance: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveApplianceId =
        widget.applianceId ?? widget.appliance?.id ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Edit Appliance'), centerTitle: true),
      body: SafeArea(
        child: StreamBuilder<ApplianceModel?>(
          stream: context.read<ApplianceProvider>().getApplianceById(
            effectiveApplianceId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !_isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }

            final appliance = snapshot.data ?? widget.appliance;
            if (appliance != null && !_isInitialized) {
              _populateFromAppliance(appliance);
              _isInitialized = true;
            }

            if (appliance == null && !_isInitialized) {
              return const Center(child: Text('Appliance not found.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Upload / Preview Box
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildPhotoWidget(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Container
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Appliance Name', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            decoration: _buildInputDecoration(
                              'e.g. Kitchen Refrigerator',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Appliance name is required'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Category', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _categoryController,
                            decoration: _buildInputDecoration(
                              'e.g. Refrigerator',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Category is required'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Brand', isRequired: true),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _brandController,
                                      decoration: _buildInputDecoration(
                                        'e.g. Samsung',
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                          ? 'Brand is required'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(
                                      'Purchase Date',
                                      isRequired: true,
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _dateController,
                                      readOnly: true,
                                      onTap: () => _selectDate(context),
                                      decoration: _buildInputDecoration(
                                        'mm/dd/yyyy',
                                        suffixIcon: IconButton(
                                          tooltip: 'Select purchase date',
                                          onPressed: () => _selectDate(context),
                                          icon: const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                          ? 'Purchase date is required'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Model Number', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _modelController,
                            decoration: _buildInputDecoration(
                              'e.g. RF28R7351SG',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Model number is required'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Serial Number'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _serialController,
                            decoration: _buildInputDecoration('Optional'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitForm(effectiveApplianceId),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhotoWidget() {
    if (_newPhotoFile != null && _newPhotoFile!.path != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_newPhotoFile!.path!), fit: BoxFit.cover),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'New Photo Selected',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }
    if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(_existingPhotoUrl!, fit: BoxFit.cover),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Tap to Change Photo',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.add_a_photo_outlined, size: 36),
        SizedBox(height: 8),
        Text('Tap to upload appliance photo'),
      ],
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        text: text,
        style: style,
        children: isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: style?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
