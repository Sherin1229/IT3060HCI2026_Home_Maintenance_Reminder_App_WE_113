import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider = context.read<AuthProvider>();
    final success = await provider.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Password changed successfully.'
                : provider.accountError ?? 'Unable to change password.',
          ),
        ),
      );
    if (success) {
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      context.pop();
    }
  }

  Widget _visibilityButton(bool visible, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      tooltip: visible ? 'Hide password' : 'Show password',
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
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
          child: provider.supportsPasswordChange
              ? Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        label: 'Current Password',
                        controller: _currentController,
                        prefixIcon: Icons.lock_outline_rounded,
                        isObscure: !_showCurrent,
                        textInputAction: TextInputAction.next,
                        suffixIcon: _visibilityButton(
                          _showCurrent,
                          () => setState(() => _showCurrent = !_showCurrent),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your current password.'
                            : null,
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      CustomTextField(
                        label: 'New Password',
                        controller: _newController,
                        prefixIcon: Icons.lock_reset_rounded,
                        isObscure: !_showNew,
                        textInputAction: TextInputAction.next,
                        suffixIcon: _visibilityButton(
                          _showNew,
                          () => setState(() => _showNew = !_showNew),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password.';
                          }
                          if (value.length < 6) {
                            return 'Password must contain at least 6 characters.';
                          }
                          if (value == _currentController.text) {
                            return 'Choose a password different from the current one.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      CustomTextField(
                        label: 'Confirm New Password',
                        controller: _confirmController,
                        prefixIcon: Icons.lock_outline_rounded,
                        isObscure: !_showConfirm,
                        textInputAction: TextInputAction.done,
                        suffixIcon: _visibilityButton(
                          _showConfirm,
                          () => setState(() => _showConfirm = !_showConfirm),
                        ),
                        validator: (value) => value != _newController.text
                            ? 'Passwords do not match.'
                            : null,
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      PrimaryButton(
                        text: 'Change Password',
                        onPressed: provider.isPasswordChanging
                            ? null
                            : _changePassword,
                        isLoading: provider.isPasswordChanging,
                      ),
                    ],
                  ),
                )
              : const _UnavailablePasswordState(),
        ),
      ),
    );
  }
}

class _UnavailablePasswordState extends StatelessWidget {
  const _UnavailablePasswordState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            const Icon(Icons.info_outline_rounded, size: 44),
            const SizedBox(height: 12),
            Text(
              'Password change is unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This account uses a federated sign-in provider. Manage its password through that provider.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
