import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    Widget profileContent;

    if (authProvider.isProfileLoading) {
      profileContent = const _ProfileStateCard(
        icon: Icons.person_search_rounded,
        title: 'Loading profile',
        message: 'Your profile details are being loaded.',
        showProgressIndicator: true,
      );
    } else if (authProvider.profileError != null) {
      profileContent = _ProfileStateCard(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
        title: 'Error loading profile',
        message: authProvider.profileError!,
        actionLabel: 'Try Again',
        onAction: () {
          context.read<AuthProvider>().loadUserProfile();
        },
      );
    } else if (authProvider.userProfile == null) {
      profileContent = const _ProfileStateCard(
        icon: Icons.person_off_outlined,
        title: 'Profile data unavailable',
        message: 'Your profile details are not available at the moment.',
      );
    } else {
      profileContent = _ProfileDetails(
        fullName: authProvider.fullName,
        email: authProvider.email,
        phoneNumber: authProvider.phone,
        profileImageUrl: null,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingMedium,
            AppConstants.paddingMedium,
            AppConstants.paddingMedium,
            AppConstants.paddingLarge,
          ),
          children: [
            Text('My Profile', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'View your account and contact information.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            profileContent,

            const SizedBox(height: 32),

            OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();

                if (!context.mounted) return;

                context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(
                  color: AppColors.border,
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;

  const _ProfileDetails({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.profileImageUrl,
  });

  String? get _initials {
    if (fullName == null) return null;

    final nameParts = fullName!.split(RegExp(r'\s+'));
    if (nameParts.length == 1) {
      return nameParts.first.substring(0, 1).toUpperCase();
    }

    return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProfileImage = profileImageUrl != null;

    return Column(
      children: [
        Semantics(
          label: 'User profile image',
          image: true,
          child: CircleAvatar(
            radius: 52,
            backgroundColor: const Color(0xFFDBEAFE),
            backgroundImage: hasProfileImage
                ? NetworkImage(profileImageUrl!)
                : null,
            child: hasProfileImage
                ? null
                : _initials == null
                ? const Icon(
                    Icons.person_outline_rounded,
                    size: 52,
                    color: AppColors.primaryBlue,
                  )
                : Text(
                    _initials!,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Text(
          fullName ?? 'Name not available',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          email ?? 'Email not available',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                _ProfileInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Full name',
                  value: fullName ?? 'Not available',
                ),
                const Divider(height: 32, color: AppColors.border),
                _ProfileInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email address',
                  value: email ?? 'Not available',
                ),
                const Divider(height: 32, color: AppColors.border),
                _ProfileInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone number',
                  value: phoneNumber ?? 'Not provided',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStateCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final bool showProgressIndicator;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ProfileStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor = AppColors.primaryBlue,
    this.showProgressIndicator = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: 40,
        ),
        child: Column(
          children: [
            if (showProgressIndicator)
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 36),
              ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppConstants.paddingLarge),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
