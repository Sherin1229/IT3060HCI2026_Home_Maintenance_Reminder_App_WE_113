import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: .88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF123E9D),
              AppColors.primaryBlue,
              Color(0xFF38A9F4),
            ],
            stops: [0, .52, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoSize = (constraints.maxWidth * .43).clamp(142.0, 180.0);
              return Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(painter: _SplashBackgroundPainter()),
                  Positioned(
                    top: constraints.maxHeight * .24,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: logoSize,
                              height: logoSize,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(34),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33052B70),
                                    blurRadius: 32,
                                    offset: Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: const AppLogo(fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'HomiQ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Smart care for your home',
                              style: TextStyle(
                                color: Color(0xFFE2F2FF),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  const _SplashBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = Colors.white.withValues(alpha: .09);
    canvas.drawCircle(
      Offset(size.width * 1.02, size.height * .02),
      size.width * .48,
      glow,
    );
    canvas.drawCircle(Offset(-12, size.height * .35), size.width * .13, glow);

    final upperWave = Path()
      ..moveTo(0, size.height * .18)
      ..cubicTo(
        size.width * .25,
        size.height * .31,
        size.width * .68,
        size.height * .27,
        size.width,
        size.height * .4,
      )
      ..lineTo(size.width, size.height * .48)
      ..cubicTo(
        size.width * .62,
        size.height * .34,
        size.width * .26,
        size.height * .4,
        0,
        size.height * .25,
      )
      ..close();
    canvas.drawPath(
      upperWave,
      Paint()..color = Colors.white.withValues(alpha: .1),
    );

    final lowerWave = Path()
      ..moveTo(0, size.height * .76)
      ..cubicTo(
        size.width * .28,
        size.height * .67,
        size.width * .57,
        size.height * .91,
        size.width,
        size.height * .76,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      lowerWave,
      Paint()..color = const Color(0xFF84D7FB).withValues(alpha: .28),
    );

    final home = Path()
      ..moveTo(size.width * .54, size.height * .89)
      ..lineTo(size.width * .76, size.height * .78)
      ..lineTo(size.width * .96, size.height * .89)
      ..lineTo(size.width * .92, size.height * .89)
      ..lineTo(size.width * .92, size.height)
      ..lineTo(size.width * .61, size.height)
      ..lineTo(size.width * .61, size.height * .89)
      ..close();
    canvas.drawPath(home, Paint()..color = Colors.white.withValues(alpha: .11));
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .72,
        size.height * .9,
        size.width * .1,
        size.height * .1,
      ),
      Paint()..color = Colors.white.withValues(alpha: .13),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
