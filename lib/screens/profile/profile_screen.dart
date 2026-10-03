import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

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

  void _showComingSoon(String feature) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature will be available soon.')),
      );
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
        onEditProfile: () => _showComingSoon('Edit Profile'),
        onChangePassword: () => _showComingSoon('Change Password'),
        onHelpSupport: () => _showComingSoon('Help & Support'),
        onAbout: () => _showComingSoon('About HomiQ'),
        onChangePhoto: () => _showComingSoon('Profile photo editing'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingMedium,
            AppConstants.paddingLarge,
            AppConstants.paddingMedium,
            AppConstants.paddingLarge,
          ),
          children: [
            Text('My Profile', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Manage your personal information and account.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            profileContent,
            const SizedBox(height: AppConstants.paddingLarge),
            OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();

                if (!context.mounted) return;

                context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded, size: 21),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                backgroundColor: const Color(0xFFFEF2F2),
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                minimumSize: const Size(double.infinity, 54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  final String fullName;
  final String email;
  final String phoneNumber;
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onHelpSupport;
  final VoidCallback onAbout;
  final VoidCallback onChangePhoto;

  const _ProfileDetails({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onHelpSupport,
    required this.onAbout,
    required this.onChangePhoto,
  });

  String get _displayName =>
      fullName.trim().isEmpty ? 'Name not available' : fullName.trim();

  String get _displayEmail =>
      email.trim().isEmpty ? 'Email not available' : email.trim();

  String get _displayPhone =>
      phoneNumber.trim().isEmpty ? 'Not provided' : phoneNumber.trim();

  String? get _initials {
    if (fullName.trim().isEmpty) return null;

    final nameParts = fullName.trim().split(RegExp(r'\s+'));
    if (nameParts.length == 1) {
      return nameParts.first.substring(0, 1).toUpperCase();
    }

    return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              Semantics(
                label: 'User profile avatar',
                image: true,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 58,
                      backgroundColor: const Color(0xFFDBEAFE),
                      child: _initials == null
                          ? const Icon(
                              Icons.person_outline_rounded,
                              size: 56,
                              color: AppColors.primaryBlue,
                            )
                          : Text(
                              _initials!,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: AppColors.primaryBlue,
                                fontSize: 32,
                              ),
                            ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 2,
                      child: Material(
                        color: AppColors.primaryBlue,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onChangePhoto,
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(
                              Icons.photo_camera_outlined,
                              color: AppColors.surface,
                              size: 21,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                _displayName,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _displayEmail,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              OutlinedButton.icon(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  minimumSize: const Size(180, 48),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const _SectionHeading(
          icon: Icons.manage_accounts_outlined,
          title: 'Personal Information',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingSmall,
            ),
            child: Column(
              children: [
                _ProfileInfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Full Name',
                  value: _displayName,
                ),
                const Divider(height: 1, color: AppColors.border),
                _ProfileInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: _displayEmail,
                ),
                const Divider(height: 1, color: AppColors.border),
                _ProfileInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: _displayPhone,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        const _SectionHeading(icon: Icons.settings_outlined, title: 'Account'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _AccountMenuRow(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.secondaryTeal,
                iconBackground: const Color(0xFFCCFBF1),
                label: 'Change Password',
                onTap: onChangePassword,
              ),
              const Divider(
                height: 1,
                indent: 72,
                endIndent: AppConstants.paddingMedium,
                color: AppColors.border,
              ),
              _AccountMenuRow(
                icon: Icons.help_outline_rounded,
                iconColor: AppColors.primaryBlue,
                iconBackground: const Color(0xFFEFF6FF),
                label: 'Help & Support',
                onTap: onHelpSupport,
              ),
              const Divider(
                height: 1,
                indent: 72,
                endIndent: AppConstants.paddingMedium,
                color: AppColors.border,
              ),
              _AccountMenuRow(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primaryDark,
                iconBackground: const Color(0xFFE0E7FF),
                label: 'About HomiQ',
                onTap: onAbout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeading({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 23),
          ),
          const SizedBox(width: 14),
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
      ),
    );
  }
}

class _AccountMenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final VoidCallback onTap;

  const _AccountMenuRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
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
          vertical: 36,
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
