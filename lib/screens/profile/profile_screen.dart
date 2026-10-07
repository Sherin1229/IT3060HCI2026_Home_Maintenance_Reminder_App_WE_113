import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
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

  Future<void> _changeProfilePhoto() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (result == null || !mounted) return;
    final extension = result.extension?.toLowerCase();
    if (!const ['jpg', 'jpeg', 'png'].contains(extension)) {
      _showMessage('Please select a JPG or PNG image.');
      return;
    }
    final size = result.lengthSync() ?? await result.length();
    if (size != null && size > 5 * 1024 * 1024) {
      _showMessage('Please select an image smaller than 5 MB.');
      return;
    }
    try {
      final bytes = await result.readAsBytes();
      if (!mounted) return;
      final provider = context.read<AuthProvider>();
      final success = await provider.uploadProfileImage(
        bytes: bytes,
        fileName: result.name,
      );
      if (!mounted) return;
      _showMessage(
        success
            ? 'Profile photo updated successfully.'
            : provider.accountError ?? 'Unable to update profile photo.',
      );
    } catch (error) {
      debugPrint('Profile image selection error: $error');
      if (mounted) _showMessage('Unable to read the selected image.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showThemeSelector() async {
    final themeProvider = context.read<ThemeProvider>();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => _ThemeSelector(
        selectedMode: themeProvider.themeMode,
        onSelected: (mode) async {
          await themeProvider.setThemeMode(mode);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final themeMode = context.watch<ThemeProvider>().themeMode;

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
        photoUrl: authProvider.photoUrl,
        isPhotoUploading: authProvider.isPhotoUploading,
        onEditProfile: () => context.push('/profile/edit'),
        onChangePassword: () => context.push('/profile/change-password'),
        onHelpSupport: () => context.push('/profile/help'),
        onAbout: () => context.push('/profile/about'),
        onChangePhoto: _changeProfilePhoto,
        themeMode: themeMode,
        onSelectTheme: _showThemeSelector,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingMedium,
            AppConstants.paddingLarge,
            AppConstants.paddingMedium,
            AppConstants.paddingLarge,
          ),
          children: [
            Text(
              'My Profile',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Manage your personal information and account.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
                backgroundColor: AppColors.errorSurface(context),
                side: BorderSide(
                  color: AppColors.errorOutline(context),
                  width: 1.5,
                ),
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
  final String photoUrl;
  final bool isPhotoUploading;
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onHelpSupport;
  final VoidCallback onAbout;
  final VoidCallback onChangePhoto;
  final ThemeMode themeMode;
  final VoidCallback onSelectTheme;

  const _ProfileDetails({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.photoUrl,
    required this.isPhotoUploading,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onHelpSupport,
    required this.onAbout,
    required this.onChangePhoto,
    required this.themeMode,
    required this.onSelectTheme,
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
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: ClipOval(
                        child: photoUrl.trim().isEmpty
                            ? _AvatarFallback(initials: _initials, theme: theme)
                            : Image.network(
                                photoUrl,
                                width: 116,
                                height: 116,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _AvatarFallback(
                                      initials: _initials,
                                      theme: theme,
                                    ),
                              ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 2,
                      child: Material(
                        color: theme.colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: isPhotoUploading ? null : onChangePhoto,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: isPhotoUploading
                                ? Padding(
                                    padding: EdgeInsets.all(11),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                  )
                                : Icon(
                                    Icons.photo_camera_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
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
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _displayEmail,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              OutlinedButton.icon(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.blueSurface(context),
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: AppColors.primaryOutline(context)),
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
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                _ProfileInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: _displayEmail,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
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
        const _SectionHeading(
          icon: Icons.palette_outlined,
          title: 'Appearance',
        ),
        const SizedBox(height: 12),
        Card(
          child: _AccountMenuRow(
            icon: Icons.brightness_6_outlined,
            iconColor: theme.colorScheme.primary,
            iconBackground: Theme.of(context).colorScheme.primaryContainer,
            label: 'Theme',
            trailingText: switch (themeMode) {
              ThemeMode.system => 'System',
              ThemeMode.light => 'Light',
              ThemeMode.dark => 'Dark',
            },
            onTap: onSelectTheme,
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
                iconColor: theme.colorScheme.secondary,
                iconBackground: AppColors.tealSurface(context),
                label: 'Change Password',
                onTap: onChangePassword,
              ),
              Divider(
                height: 1,
                indent: 72,
                endIndent: AppConstants.paddingMedium,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              _AccountMenuRow(
                icon: Icons.help_outline_rounded,
                iconColor: theme.colorScheme.primary,
                iconBackground: AppColors.blueSurface(context),
                label: 'Help & Support',
                onTap: onHelpSupport,
              ),
              Divider(
                height: 1,
                indent: 72,
                endIndent: AppConstants.paddingMedium,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              _AccountMenuRow(
                icon: Icons.info_outline_rounded,
                iconColor: Theme.of(context).colorScheme.tertiary,
                iconBackground: Theme.of(context).colorScheme.tertiaryContainer,
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

class _AvatarFallback extends StatelessWidget {
  final String? initials;
  final ThemeData theme;

  const _AvatarFallback({required this.initials, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: Center(
        child: initials == null
            ? Icon(
                Icons.person_outline_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              )
            : Text(
                initials!,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 32,
                ),
              ),
      ),
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
        Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.blueSurface(context),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
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
  final String? trailingText;

  const _AccountMenuRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.onTap,
    this.trailingText,
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.selectedMode, required this.onSelected});

  final ThemeMode selectedMode;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingLarge,
        4,
        AppConstants.paddingLarge,
        AppConstants.paddingLarge + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Choose Theme', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Select how HomiQ should look on this device.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _ThemeOption(
            icon: Icons.settings_brightness_rounded,
            title: 'System Default',
            subtitle: 'Follow your device appearance',
            value: ThemeMode.system,
            groupValue: selectedMode,
            onSelected: onSelected,
          ),
          _ThemeOption(
            icon: Icons.light_mode_outlined,
            title: 'Light',
            subtitle: 'Always use the light theme',
            value: ThemeMode.light,
            groupValue: selectedMode,
            onSelected: onSelected,
          ),
          _ThemeOption(
            icon: Icons.dark_mode_outlined,
            title: 'Dark',
            subtitle: 'Always use the dark theme',
            value: ThemeMode.dark,
            groupValue: selectedMode,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
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
    final effectiveIconColor =
        iconColor == AppColors.primaryBlue &&
            theme.brightness == Brightness.dark
        ? theme.colorScheme.primary
        : iconColor;

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
                  color: effectiveIconColor.withAlpha(
                    theme.brightness == Brightness.dark ? 48 : 20,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: effectiveIconColor, size: 36),
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
