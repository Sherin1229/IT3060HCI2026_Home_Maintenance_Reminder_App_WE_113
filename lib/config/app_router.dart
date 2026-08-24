import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/appliances/appliances_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/warranties/warranties_screen.dart';
import '../screens/maintenance_history/maintenance_history_screen.dart';
import '../screens/profile/profile_screen.dart';

/// Centralized Router for HomiQ
/// Defines routing hierarchy using GoRouter.
/// Utilizes a ShellRoute for persistent bottom navigation on main pages.
class AppRouter {
  AppRouter._();

  // Root navigator key for dialogs or overlays that need to be shown outside the navigation shell
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    routes: [
      // Authentication Routes (outside the shell layout)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Standalone Routes pushed on top of the main navigation shell
      GoRoute(
        path: '/maintenance-history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MaintenanceHistoryScreen(),
      ),

      // Main Navigation Shell (includes the persistent BottomNavigationBar)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationShell(
            state: state,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/appliances',
            builder: (context, state) => const AppliancesScreen(),
          ),
          GoRoute(
            path: '/reminders',
            builder: (context, state) => const RemindersScreen(),
          ),
          GoRoute(
            path: '/warranties',
            builder: (context, state) => const WarrantiesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

/// The Navigation Shell wrapper which renders the BottomNavigationBar
/// and retains the correct tab selected state.
class MainNavigationShell extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.state,
    required this.child,
  });

  // Calculate the currently active index based on route path matching
  int _getCurrentIndex() {
    final String location = state.uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/appliances')) return 1;
    if (location.startsWith('/reminders')) return 2;
    if (location.startsWith('/warranties')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/appliances');
        break;
      case 2:
        context.go('/reminders');
        break;
      case 3:
        context.go('/warranties');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getCurrentIndex(),
        onTap: (index) => _onTabTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen_rounded),
            label: 'Appliances',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_rounded),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_rounded),
            label: 'Warranties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
