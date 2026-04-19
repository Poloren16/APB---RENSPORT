import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/auth_data.dart';
import '../utils/alert_utils.dart';

class ResetPasswordPage extends StatefulWidget {
  final String username;
  const ResetPasswordPage({super.key, required this.username});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _handleResetPassword() async {
    String password = _passwordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPass.isEmpty) {
      AlertUtils.showToast(context, 'Harap isi semua kolom', isSuccess: false);
      return;
    }

    if (password.length < 6) {
      AlertUtils.showToast(context, 'Kata sandi minimal 6 karakter', isSuccess: false);
      return;
    }

    if (password != confirmPass) {
      AlertUtils.showToast(context, 'Konfirmasi kata sandi tidak cocok', isSuccess: false);
      return;
    }

    // Update the password in local storage
    await GlobalAuthData.updateAccount(
      widget.username,
      newPassword: password,
    );

    AlertUtils.showResultDialog(
      context,
      isSuccess: true,
      title: 'Kata Sandi Diperbarui!',
      message: 'Kata sandi Anda telah berhasil diubah. Silakan masuk dengan kata sandi baru Anda.',
      onConfirm: () {
        // Pop back to login (pop twice since we are in ResetPasswordPage <- ForgotPasswordPage <- LoginPage)
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Atur Ulang Kata Sandi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hampir selesai! Masukkan kata sandi baru Anda di bawah ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              
              const Text(
                'Kata Sandi Baru',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Minimal 6 karakter',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Konfirmasi Kata Sandi Baru',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: const InputDecoration(
                  hintText: 'Ulangi kata sandi baru',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 48),
              
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan Kata Sandi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
