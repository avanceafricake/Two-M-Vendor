import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'theme.dart';
import 'firebase_options.dart';
import 'services/service_locator.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/startup_gate.dart';
import 'screens/splash/app_splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture all uncaught Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    // Also print a concise line for Dreamflow console
    // ignore: avoid_print
    print('[FlutterError] ${details.exceptionAsString()}');
  };

  // Log startup progress to help diagnose boot issues
  // ignore: avoid_print
  print('[Startup] Ensuring Firebase initialization...');
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // ignore: avoid_print
    print('[Startup] Firebase.initializeApp() completed');
  } catch (e, st) {
    // ignore: avoid_print
    print('[Startup][FATAL] Firebase initialization failed: $e');
    // ignore: avoid_print
    print(st);
  }

  // Initialize Service Locator
  try {
    ServiceLocator().initialize();
    // ignore: avoid_print
    print('[Startup] ServiceLocator initialized');
  } catch (e, st) {
    // ignore: avoid_print
    print('[Startup][FATAL] ServiceLocator initialization failed: $e');
    // ignore: avoid_print
    print(st);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Two M Vendors',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Hold the splash for ~6 seconds to meet branding requirement
    Future.delayed(const Duration(milliseconds: 6000), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const AppSplashScreen(minDisplayMs: 6000);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // ignore: avoid_print
          print('[Auth] Waiting for auth state...');
          return const AppSplashScreen(minDisplayMs: 6000);
        }

        final user = snapshot.data;
        // ignore: avoid_print
        print('[Auth] authStateChanges() -> user: ${user?.uid ?? 'null'}');
        if (user == null) {
          return const LoginScreen();
        }
        // Route through startup gate to enforce onboarding + phone verification
        return const StartupGate();
      },
    );
  }
}
