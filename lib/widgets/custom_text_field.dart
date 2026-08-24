import 'package:flutter/material.dart';

/// HomiQ Reusable Text Input Field
/// Encapsulates consistent input design, validation feedback, accessibility semantics,
/// and clear focus/error states following HCI principles.
class CustomTextField extends StatelessWidget {
  /// Label text displayed above or inside the field.
  final String label;

  /// Optional helper/hint text.
  final String? hintText;

  /// Controller for text editing.
  final TextEditingController? controller;

  /// Obscures text (e.g. for password inputs).
  final bool isObscure;

  /// Keyboard type (e.g. email, phone, number).
  final TextInputType keyboardType;

  /// Optional form validation callback.
  final String? Function(String?)? validator;

  /// Optional prefix icon to clarify input type (e.g. Lock, Email).
  final IconData? prefixIcon;

  /// Optional suffix widget (e.g. password visibility toggle).
  final Widget? suffixIcon;

  /// Keyboard action button behavior (e.g. done, next).
  final TextInputAction? textInputAction;

  /// Change callback.
  final ValueChanged<String>? onChanged;

  /// Whether the text field is interactable.
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.isObscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: label,
      hint: hintText,
      textField: true,
      enabled: enabled,
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: textInputAction,
        onChanged: onChanged,
        enabled: enabled,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: enabled ? theme.colorScheme.onSurface : theme.disabledColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 22) : null,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
