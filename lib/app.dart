import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'components/loading_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/gestures.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class HabitikApp extends StatelessWidget {
  const HabitikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitik',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CL'),
        Locale('es', ''),
      ],
      locale: const Locale('es', 'CL'),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) return const LoadingScreen();
          if (auth.user == null) return const LoginScreen();
          // While onboarding is running, stay in OnboardingScreen even if familyId gets set
          if (auth.onboardingActive || auth.profile?.familyId == null) {
            return const OnboardingScreen();
          }
          return const DashboardScreen();
        },
      ),
    );
  }
}
