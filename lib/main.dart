import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/booking_history.dart';
import 'pages/payment_page.dart';
import 'theme/app_colors.dart';

void main() {
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
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter', // Assuming we would use a modern font like Inter
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
      routes: {
        '/booking': (context) => const BookingPage(),
        '/payment': (context) => const PaymentPage(),
      },
    );
  }
}
