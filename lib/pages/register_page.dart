import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:rensius/data/auth_data.dart';
import 'package:rensius/utils/alert_utils.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isPasswordVisible = false;
  // Phone prefix is now fixed to +62
  
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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

  void _handleRegister() {
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

    // 5. Password Length
    if (password.length < 6) {
      _showError('Kata sandi minimal 6 karakter.');
      return;
    }

    // 6. Username Availability
    if (GlobalAuthData.usernameExists(username)) {
      _showError('Nama pengguna sudah digunakan. Silakan pilih yang lain.');
      return;
    }

    // Register to mock database
    final newAccount = UserAccount(
      username: username,
      password: password,
      role: 'End User',
      applicantName: name,
      email: email,
      phoneNumber: '+62$phone',
    );
    GlobalAuthData.registerAccount(newAccount);

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
    );
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
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nama sesuai KTP',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildLabel('Email'),
                TextFormField(
                  controller: _emailController,
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
                const SizedBox(height: 16),
                
                _buildLabel('Konfirmasi Kata Sandi'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
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
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Daftar Sekarang',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
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
      decoration: InputDecoration(
        hintText: '8123456789',
        prefixIcon: Container(
          width: 50,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: const Text('+62', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}
