import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/auth_data.dart';
import '../utils/alert_utils.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _inputController = TextEditingController();

  void _handleResetRequest() {
    String input = _inputController.text.trim();

    if (input.isEmpty) {
      AlertUtils.showToast(context, 'Harap masukkan email atau nomor telepon Anda', isSuccess: false);
      return;
    }

    // If it looks like an email, validate email format
    if (input.contains('@')) {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(input)) {
        AlertUtils.showToast(context, 'Format email tidak valid', isSuccess: false);
        return;
      }
    } else {
      // Validate phone number format (numbers, spaces, dashes, optionally start with +)
      final phoneRegex = RegExp(r'^\+?[0-9\s\-]{7,15}$');
      if (!phoneRegex.hasMatch(input)) {
        AlertUtils.showToast(context, 'Format nomor telepon tidak valid', isSuccess: false);
        return;
      }
    }

    final account = GlobalAuthData.getAccountByEmailOrPhone(input);

    if (account != null) {
      // In a real app, we would send an OTP or email.
      // For this demo, we'll navigate directly to password reset.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(username: account.username),
        ),
      );
    } else {
      AlertUtils.showResultDialog(
        context,
        isSuccess: false,
        title: 'Akun Tidak Ditemukan',
        message: 'Maaf, akun dengan email atau nomor telepon tersebut tidak ditemukan.',
      );
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Lupa Kata Sandi?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Jangan khawatir! Masukkan alamat email atau nomor telepon yang terdaftar '
                'dan kami akan membantu Anda memulihkan akun.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Email atau Nomor Telepon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _inputController,
                keyboardType: TextInputType.text,
                scrollPadding: const EdgeInsets.only(bottom: 200),
                decoration: const InputDecoration(
                  hintText: 'nama@email.com atau 08123xxx',
                  prefixIcon: Icon(Icons.contact_mail_outlined, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleResetRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Lanjutkan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ingat kata sandi?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Masuk Kembali',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
