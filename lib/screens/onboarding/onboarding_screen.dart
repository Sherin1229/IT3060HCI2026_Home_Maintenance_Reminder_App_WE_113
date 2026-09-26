import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/app_logo.dart';

class OnboardingItem {
  final String title;
  final String description;
  final String imagePath;
  final IconData fallbackIcon;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.fallbackIcon,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    OnboardingItem(
      title: 'Manage Your Appliances',
      description: 'Keep all your home appliances organized in one place.',
      imagePath: 'assets/images/onboarding_appliances.png',
      fallbackIcon: Icons.kitchen_rounded,
    ),
    OnboardingItem(
      title: 'Never Miss Maintenance',
      description:
          'Get timely reminders and keep your appliances running smoothly.',
      imagePath: 'assets/images/onboarding_reminders.png',
      fallbackIcon: Icons.notifications_active_rounded,
    ),
    OnboardingItem(
      title: 'Keep Warranties Safe',
      description:
          'Store warranty information and keep important appliance details within reach.',
      imagePath: 'assets/images/onboarding_warranty.png',
      fallbackIcon: Icons.verified_user_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() => context.go('/login');

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _goToLogin();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 690;
            return Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _OnboardingBackgroundPainter()),
                Column(
                  children: [
                    _OnboardingHeader(
                      currentPage: _currentPage,
                      pageCount: _pages.length,
                      onSkip: _goToLogin,
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) => _OnboardingPage(
                          item: _pages[index],
                          compact: compact,
                        ),
                      ),
                    ),
                    _OnboardingAction(
                      isLastPage: _currentPage == _pages.length - 1,
                      compact: compact,
                      onPressed: _nextPage,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final VoidCallback onSkip;

  const _OnboardingHeader({
    required this.currentPage,
    required this.pageCount,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 12, 2),
      child: SizedBox(
        height: 68,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: AppLogo(width: 66, height: 66),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(pageCount, (index) {
                final selected = currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: selected ? 18 : 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryBlue
                        : const Color(0xFFD7E4F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            if (currentPage < pageCount - 1)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    minimumSize: const Size(64, 48),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final bool compact;

  const _OnboardingPage({required this.item, required this.compact});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationHeight =
            (constraints.maxHeight * (compact ? .53 : .56))
                .clamp(190.0, constraints.maxWidth * .94)
                .toDouble();
        final titleSize = constraints.maxWidth < 350 ? 21.0 : 23.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppConstants.paddingMedium,
            compact ? 0 : 4,
            AppConstants.paddingMedium,
            0,
          ),
          child: Column(
            children: [
              SizedBox(
                height: illustrationHeight,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: illustrationHeight * .86,
                      height: illustrationHeight * .86,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFFE8F8FC), Color(0x00E8F8FC)],
                        ),
                      ),
                    ),
                    Image.asset(
                      item.imagePath,
                      width: double.infinity,
                      height: illustrationHeight,
                      fit: BoxFit.contain,
                      semanticLabel: item.title,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        item.fallbackIcon,
                        size: compact ? 120 : 150,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 7 : 11),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.55,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 8 : 11),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: compact ? 14 : 15.5,
                    height: 1.4,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(height: compact ? 8 : 14),
            ],
          ),
        );
      },
    );
  }
}

class _OnboardingAction extends StatelessWidget {
  final bool isLastPage;
  final bool compact;
  final VoidCallback onPressed;

  const _OnboardingAction({
    required this.isLastPage,
    required this.compact,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, compact ? 12 : 24),
      child: Align(
        alignment: isLastPage ? Alignment.center : Alignment.centerRight,
        child: SizedBox(
          width: isLastPage ? double.infinity : 132,
          height: 54,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: AppColors.primaryBlue.withValues(alpha: .3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLastPage ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingBackgroundPainter extends CustomPainter {
  const _OnboardingBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final backWave = Path()
      ..moveTo(0, size.height * .83)
      ..cubicTo(
        size.width * .22,
        size.height * .79,
        size.width * .4,
        size.height * .91,
        size.width * .66,
        size.height * .86,
      )
      ..cubicTo(
        size.width * .83,
        size.height * .82,
        size.width * .92,
        size.height * .8,
        size.width,
        size.height * .81,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backWave, Paint()..color = const Color(0xFFE9F6FF));

    final frontWave = Path()
      ..moveTo(0, size.height * .87)
      ..cubicTo(
        size.width * .2,
        size.height * .84,
        size.width * .39,
        size.height * .94,
        size.width * .67,
        size.height * .89,
      )
      ..cubicTo(
        size.width * .82,
        size.height * .86,
        size.width * .93,
        size.height * .85,
        size.width,
        size.height * .86,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(frontWave, Paint()..color = const Color(0xFFD9F0FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
