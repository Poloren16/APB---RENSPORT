import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../data/auth_data.dart';
import '../utils/alert_utils.dart';
import '../services/supabase_service.dart';
import '../services/supabase_auth_service.dart';

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
  bool _isLoading = false;

  void _handleResetPassword() async {
    String password = _passwordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPass.isEmpty) {
      AlertUtils.showToast(context, 'Harap isi semua kolom', isSuccess: false);
      return;
    }

    final uppercaseRegex = RegExp(r'[A-Z]');
    final numericRegex = RegExp(r'[0-9]');
    final symbolRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\\\/\[\]]');

    if (password.length < 8 ||
        !uppercaseRegex.hasMatch(password) ||
        !numericRegex.hasMatch(password) ||
        !symbolRegex.hasMatch(password)) {
      AlertUtils.showToast(context, 'Kata sandi harus minimal 8 karakter dan mengandung minimal 1 huruf kapital, 1 angka, dan 1 simbol.', isSuccess: false);
      return;
    }

    if (password != confirmPass) {
      AlertUtils.showToast(context, 'Konfirmasi kata sandi tidak cocok', isSuccess: false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final account = GlobalAuthData.getAccount(widget.username);
      if (account == null) {
        AlertUtils.showToast(context, 'Akun tidak ditemukan.', isSuccess: false);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 1. Sinkronisasi dengan Supabase Auth jika aktif
      if (SupabaseService.isInitialized && account.role != 'Admin' && account.email.isNotEmpty) {
        bool loggedIn = false;
        bool isNetworkError = false;

        if (account.password.isNotEmpty) {
          try {
            await SupabaseAuthService.signInWithEmail(
              email: account.email,
              password: account.password,
            );
            loggedIn = true;
          } on AuthException catch (e) {
            final msg = e.message.toLowerCase();
            if (msg.contains('network') || msg.contains('connect') || msg.contains('request failed')) {
              isNetworkError = true;
            }
          } catch (e) {
            isNetworkError = true;
          }
        }

        if (isNetworkError) {
          AlertUtils.showToast(context, 'Koneksi internet bermasalah. Coba lagi beberapa saat.', isSuccess: false);
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (loggedIn) {
          try {
            await SupabaseAuthService.updatePassword(password);
            await SupabaseAuthService.signOut();
          } on AuthException catch (e) {
            AlertUtils.showToast(
              context,
              AlertUtils.sanitizeErrorMessage('Gagal memperbarui kata sandi di Supabase: ${e.message}'),
              isSuccess: false,
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } else {
          // Self-healing: daftarkan ulang user ke Supabase Auth dengan kata sandi baru
          try {
            final tempAccount = UserAccount(
              username: account.username,
              password: password,
              role: account.role,
              applicantName: account.applicantName,
              email: account.email,
              phoneNumber: account.phoneNumber,
              bio: account.bio,
              sportsInterests: account.sportsInterests,
              instagram: account.instagram,
              twitter: account.twitter,
              facebook: account.facebook,
              profileImagePath: account.profileImagePath,
              ktpImagePath: account.ktpImagePath,
              gender: account.gender,
              dateOfBirth: account.dateOfBirth,
              points: account.points,
              cart: account.cart,
              favorites: account.favorites,
            );
            await SupabaseAuthService.registerEndUser(account: tempAccount);
            await SupabaseAuthService.signOut();
          } catch (signUpErr) {
            print('Pendaftaran mandiri gagal saat reset sandi: $signUpErr');
          }
        }
      }

      // 2. Update kata sandi secara lokal
      await GlobalAuthData.updateAccount(
        widget.username,
        newPassword: password,
      );

      if (mounted) {
        AlertUtils.showResultDialog(
          context,
          isSuccess: true,
          title: 'Kata Sandi Diperbarui!',
          message: 'Kata sandi Anda telah berhasil diubah. Silakan masuk dengan kata sandi baru Anda.',
          onConfirm: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      }
    } catch (e) {
      AlertUtils.showToast(context, 'Gagal memperbarui kata sandi. Silakan coba lagi.', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                enabled: !_isLoading,
                scrollPadding: const EdgeInsets.only(bottom: 200),
                decoration: InputDecoration(
                  hintText: 'Minimal 8 karakter (1 kapital, 1 angka, 1 simbol)',
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
                enabled: !_isLoading,
                scrollPadding: const EdgeInsets.only(bottom: 200),
                decoration: const InputDecoration(
                  hintText: 'Ulangi kata sandi baru',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 48),
              
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan Kata Sandi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
