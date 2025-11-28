import 'package:flutter/material.dart';

import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/screens/onboarding_screen.dart';
import '../../features/authentication/presentation/screens/role_selection_screen.dart';
import '../../features/authentication/presentation/screens/phone_auth_screen.dart';
import '../../features/authentication/presentation/screens/verify_code_screen.dart';
import '../../features/authentication/presentation/screens/profile_setup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

class AppRouter {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case '/role-selection':
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());

      case '/phone-auth':
        // Rolle kommt als String-Argument: "woman" oder "man"
        final role = settings.arguments as String? ?? 'woman';
        return MaterialPageRoute(
          builder: (_) => PhoneAuthScreen(role: role),
        );

      case '/verify-code':
        final args = settings.arguments as Map<String, dynamic>;
        final phoneNumber = args['phoneNumber'] as String;
        final verificationId = args['verificationId'] as String;
        final role = args['role'] as String;
        return MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(
            phoneNumber: phoneNumber,
            verificationId: verificationId,
            role: role,
          ),
        );

      case '/profile-setup':
        final args = settings.arguments as Map<String, dynamic>;
        final phoneNumber = args['phoneNumber'] as String;
        final role = args['role'] as String;
        return MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(
            phoneNumber: phoneNumber,
            role: role,
          ),
        );

      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('404 – Route nicht gefunden')),
          ),
        );
    }
  }
}