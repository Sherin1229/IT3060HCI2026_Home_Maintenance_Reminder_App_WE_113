import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/appliance_model.dart';
import '../providers/appliance_provider.dart';

class ApplianceSelectionField extends StatelessWidget {
  final String? selectedApplianceId;
  final ValueChanged<ApplianceModel?> onChanged;
  final String label;
  final bool isRequired;
  final String? errorText;

  const ApplianceSelectionField({
    super.key,
    required this.selectedApplianceId,
    required this.onChanged,
    this.label = 'Appliance (Optional)',
    this.isRequired = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<ApplianceModel>>(
      stream: context.read<ApplianceProvider>().getUserAppliances(user.uid),
      builder: (context, snapshot) {
        final appliances = snapshot.data ?? const <ApplianceModel>[];

        final selectedExists = appliances.any(
          (appliance) => appliance.id == selectedApplianceId,
        );

        final selectedMissing =
            selectedApplianceId != null && !selectedExists;

        if (snapshot.hasError) {
          return _ApplianceSelectorMessage(
            label: label,
            message: 'Unable to load appliances. Please try again.',
            icon: Icons.error_outline_rounded,
            errorText: errorText,
          );
        }

        if (snapshot.connectionState != ConnectionState.waiting &&
            appliances.isEmpty &&
            !selectedMissing) {
          return _ApplianceSelectorMessage(
            label: label,
            message: isRequired
                ? 'Add an appliance before continuing.'
                : 'No appliances added yet. You can continue without one.',
            icon: Icons.kitchen_outlined,
            errorText: errorText,
            action: OutlinedButton.icon(
              onPressed: () => context.push('/appliances/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Appliance'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),

            DropdownButtonFormField<String?>(
              key: ValueKey(
                '$selectedApplianceId-${appliances.length}',
              ),
              initialValue: selectedApplianceId,

              // Prevents horizontal overflow inside the dropdown field.
              isExpanded: true,

              decoration: InputDecoration(
                hintText:
                    snapshot.connectionState == ConnectionState.waiting
                        ? 'Loading appliances...'
                        : isRequired
                        ? 'Select appliance'
                        : 'No linked appliance',
                errorText: errorText,
                prefixIcon: const Icon(
                  Icons.kitchen_outlined,
                ),
              ),

              items: [
                if (!isRequired)
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'No linked appliance',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                if (selectedMissing)
                  DropdownMenuItem<String?>(
                    value: selectedApplianceId,
                    child: const Text(
                      'Linked appliance is unavailable',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                ...appliances.map(
                  (appliance) => DropdownMenuItem<String?>(
                    value: appliance.id,
                    child: Text(
                      '${appliance.applianceName} — '
                      '${appliance.brand} • '
                      '${appliance.modelNumber}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],

              onChanged:
                  snapshot.connectionState == ConnectionState.waiting
                      ? null
                      : (id) {
                          ApplianceModel? selected;

                          for (final appliance in appliances) {
                            if (appliance.id == id) {
                              selected = appliance;
                              break;
                            }
                          }

                          onChanged(selected);
                        },
            ),

            if (selectedMissing) ...[
              const SizedBox(height: 6),
              Text(
                'The previously linked appliance is unavailable. '
                'Select another appliance to change the relationship.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
              ),
            ],

            if (appliances.isEmpty && selectedMissing) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/appliances/add'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Appliance'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ApplianceSelectorMessage extends StatelessWidget {
  final String label;
  final String message;
  final IconData icon;
  final Widget? action;
  final String? errorText;

  const _ApplianceSelectorMessage({
    required this.label,
    required this.message,
    required this.icon,
    this.action,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),

              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              if (action != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: action!,
                ),
              ],
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
