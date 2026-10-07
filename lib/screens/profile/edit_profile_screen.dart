import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final provider = context.read<AuthProvider>();
    _nameController.text = provider.fullName;
    _emailController.text = provider.currentUser?.email ?? provider.email;
    _phoneController.text = provider.phone;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider = context.read<AuthProvider>();
    final success = await provider.updateProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile updated successfully.'
                : provider.accountError ?? 'Unable to update profile.',
          ),
        ),
      );
    if (success) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back to profile',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Full Name',
                  hintText: 'Enter your full name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Please enter your full name.';
                    if (name.length < 2) return 'Please enter a valid name.';
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomTextField(
                  label: 'Account Email',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: false,
                ),
                const SizedBox(height: 6),
                Text(
                  'Your account email is managed by Firebase Authentication.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomTextField(
                  label: 'Phone Number',
                  hintText: 'Enter your phone number',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return null;
                    if (!RegExp(r'^[0-9+()\-\s]{7,20}$').hasMatch(phone)) {
                      return 'Please enter a valid phone number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                PrimaryButton(
                  text: 'Save Changes',
                  onPressed: provider.isProfileSaving ? null : _save,
                  isLoading: provider.isProfileSaving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
