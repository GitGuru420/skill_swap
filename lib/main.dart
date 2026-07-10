import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/auth/registration_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://mvtgzdpmprlrzotimrgk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im12dGd6ZHBtcHJscnpvdGltcmdrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2OTEwNTYsImV4cCI6MjA5OTI2NzA1Nn0.KGmQ92ZqitbuEHdLqP7PUKN7PjFvfsTevqQh2Xgwqlc',
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
        '/login': (context) => const DummyLoginScreen(),
        '/register': (context) => const RegistrationScreen(),
      },
    );
  }
}

// Temporary placeholder screen for compile purposes
class DummyLoginScreen extends StatelessWidget {
  const DummyLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Placeholder')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/register');
          },
          child: const Text('Go to Registration Screen'),
        ),
      ),
    );
  }
}