import 'package:flutter/material.dart';
import 'package:rensius/pages/login_page.dart';
import 'package:rensius/theme/app_colors.dart';
import 'package:rensius/data/auth_data.dart';
import 'package:rensius/data/verification_data.dart';
import 'package:rensius/data/venue_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Environment Variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Mock Database Persistence
  await GlobalVerificationData.init();
  await GlobalAuthData.init();
  await GlobalVenueData.init();
  
  // Self-Healing: Sync missing email/phone from registration data
  await GlobalAuthData.syncWithVerificationData(GlobalVerificationData.requests);
  
  runApp(const RensiusApp());
}

class RensiusApp extends StatelessWidget {
  const RensiusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RENSIUS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
