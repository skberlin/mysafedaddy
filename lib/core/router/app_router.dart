import 'package:flutter/material.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/screens/onboarding_screen.dart';
import '../../features/authentication/presentation/screens/role_selection_screen.dart';
import '../../features/authentication/presentation/screens/phone_auth_screen.dart';
import '../../features/authentication/presentation/screens/verify_code_screen.dart';

class AppRouter {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {

      case '/splash':
        return MaterialPageRoute(builder: (_) => SplashScreen());

      case '/onboarding':
        return MaterialPageRoute(builder: (_) => OnboardingScreen());

      case '/role-selection':
        return MaterialPageRoute(builder: (_) => RoleSelectionScreen());

      case '/phone-auth':
        return MaterialPageRoute(builder: (_) => PhoneAuthScreen());

      case '/verify-code':
  final args = settings.arguments as Map<String, dynamic>;
  final phoneNumber = args['phoneNumber'] as String;
  final verificationId = args['verificationId'] as String;

  return MaterialPageRoute(
    builder: (_) => VerifyCodeScreen(
      phoneNumber: phoneNumber,
      verificationId: verificationId,
    ),
  );

      default:
        return MaterialPageRoute(builder: (_) => Scaffold(
          body: Center(child: Text('404 – Route nicht gefunden')),
        ));
    }
  }
}