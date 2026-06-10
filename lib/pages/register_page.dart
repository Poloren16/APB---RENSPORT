import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import 'package:rensius/data/auth_data.dart';
import 'package:rensius/data/verification_data.dart';
import 'package:rensius/services/supabase_auth_service.dart';
import 'package:rensius/services/supabase_service.dart';
import 'package:rensius/utils/alert_utils.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isPasswordVisible = false;
  String _selectedCountryCode = '+62';
  final List<String> _countryCodes = ['+62', '+1', '+60', '+65', '+44', '+81'];
  
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRegistering = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isRegistering) return;

    String name = _nameController.text.trim();
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    // 1. Minimum Field Validation
    if (name.isEmpty || username.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showError('Semua kolom harus diisi.');
      return;
    }

    // 2. Email Validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Format email tidak valid (contoh: nama@email.com).');
      return;
    }

    // 3. Phone Validation (7-15 digits)
    final phoneRegex = RegExp(r'^[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(phone)) {
      _showError('Nomor telepon harus berupa angka (7-15 digit).');
      return;
    }

    // 4. Password Confirmation
    if (password != confirmPass) {
      _showError('Konfirmasi kata sandi tidak cocok.');
      return;
    }

    // Strong password validation: min 8 chars, 1 uppercase, 1 digit, 1 symbol
    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~_.]).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      _showError(
        'Kata sandi harus minimal 8 karakter, mengandung setidaknya 1 huruf kapital, 1 angka, dan 1 simbol (!@#\$&*~_.).',
      );
      return;
    }

    // 6. Username Availability
    if (GlobalAuthData.usernameExists(username) || 
        GlobalVerificationData.requests.any((r) => r.username == username && r.status != 'Rejected')) {
      _showError('Nama pengguna sudah digunakan. Silakan pilih yang lain.');
      return;
    }

    // 7. Email Availability
    if (GlobalAuthData.emailExists(email) || 
        GlobalVerificationData.requests.any((r) => r.email.toLowerCase().trim() == email.toLowerCase().trim() && r.status != 'Rejected')) {
      _showError('Email ini sudah terdaftar. Silakan pilih email lain.');
      return;
    }

    // 8. Phone Number Availability
    final String fullPhone = '$_selectedCountryCode$phone';
    if (GlobalAuthData.phoneExists(fullPhone) || 
        GlobalVerificationData.requests.any((r) => r.phoneNumber?.replaceAll(RegExp(r'[^0-9]'), '') == fullPhone.replaceAll(RegExp(r'[^0-9]'), '') && r.status != 'Rejected')) {
      _showError('Nomor telepon ini sudah terdaftar. Silakan pilih nomor lain.');
      return;
    }

    if (!SupabaseService.isInitialized) {
      _showError(
        'Supabase belum aktif. Pastikan konfigurasi Supabase sudah benar, lalu jalankan ulang aplikasi.',
      );
      return;
    }

    final newAccount = UserAccount(
      username: username,
      password: password,
      role: 'End User',
      applicantName: name,
      email: email,
      phoneNumber: '$_selectedCountryCode$phone',
    );

    setState(() => _isRegistering = true);

    try {
      await SupabaseAuthService.registerEndUser(account: newAccount);
      await GlobalAuthData.registerAccount(newAccount);
    } on AuthException catch (error) {
      _showError(_supabaseAuthErrorMessage(error));
      return;
    } on Object catch (_) {
      _showError('Pendaftaran gagal karena masalah server. Silakan coba lagi beberapa saat.');
      return;
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }

    if (!mounted) return;

    AlertUtils.showResultDialog(
      context,
      isSuccess: true,
      title: 'Pendaftaran Berhasil!',
      message: 'Akun Anda telah terdaftar. Silakan masuk untuk menikmati layanan Rensius.',
      onConfirm: () {
        Navigator.pop(context);
      },
    );
  }

  void _showError(String message) {
    AlertUtils.showResultDialog(
      context,
      isSuccess: false,
      title: 'Data Tidak Valid',
      message: message,
      isUserFacing: true,
    );
  }

  String _supabaseAuthErrorMessage(AuthException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk ke akun Anda.';
    } else if (msg.contains('invalid email')) {
      return 'Format email tidak valid.';
    } else if (msg.contains('should be at least') || msg.contains('weak')) {
      return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
    } else if (msg.contains('network') || msg.contains('connect') || msg.contains('request failed')) {
      return 'Koneksi internet bermasalah. Coba lagi beberapa saat.';
    }
    return AlertUtils.sanitizeErrorMessage(error.message);
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Buat Akun Baru',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Daftar sekarang untuk mulai memesan lapangan olahraga favoritmu!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form Fields
                _buildLabel('Nama Lengkap'),
                TextFormField(
                  controller: _nameController,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nama sesuai KTP',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildLabel('Email'),
                TextFormField(
                  controller: _emailController,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                  decoration: const InputDecoration(
                    hintText: 'name@email.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildLabel('Nomor Telepon'),
                _buildPhoneField(),
                const SizedBox(height: 16),
                
                _buildLabel('Nama Pengguna'),
                TextFormField(
                  controller: _usernameController,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                  decoration: const InputDecoration(
                    hintText: 'Pilih nama pengguna yang unik',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildLabel('Kata Sandi'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                  decoration: InputDecoration(
                    hintText: 'Min. 8 karakter (Kapital, Angka, Simbol)',
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
                const SizedBox(height: 16),
                
                _buildLabel('Konfirmasi Kata Sandi'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                  decoration: const InputDecoration(
                    hintText: 'Ulangi kata sandi Anda',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Register Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isRegistering ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      _isRegistering ? 'Mendaftarkan...' : 'Daftar Sekarang',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login Link
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    const Text(
                      'Sudah punya akun?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Masuk',
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
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      scrollPadding: const EdgeInsets.only(bottom: 200),
      decoration: InputDecoration(
        hintText: '8123456789',
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              items: _countryCodes.map((code) => DropdownMenuItem(
                value: code,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              )).toList(),
              onChanged: (val) => setState(() => _selectedCountryCode = val!),
            ),
          ),
        ),
      ),
    );
  }
}
