import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/onboarding_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  // Check if onboarding has been completed before
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

  runApp(SkillSwapApp(isFirstTime: isFirstTime));
}

class SkillSwapApp extends StatelessWidget {
  final bool isFirstTime;
  const SkillSwapApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Swap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
        ),
      ),
      // If it is the first time, show Onboarding, otherwise go straight to Login placeholder
      initialRoute: isFirstTime ? '/onboarding' : '/login',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const DummyLoginScreen(), // Temporary placeholder
      },
    );
  }
}

// Temporary placeholder screen for compile purposes
class DummyLoginScreen extends StatelessWidget {
  const DummyLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Login Screen Placeholder'),
      ),
    );
  }
}