import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/home/main_screen.dart';
import '../../presentation/screens/profile/profile_settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) =>
          const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) =>
          const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) =>
          const MainScreen(),
    ),
    GoRoute(
      path: '/profile-settings',
      builder: (BuildContext context, GoRouterState state) =>
          const ProfileSettingsScreen(),
    ),
  ],
);
