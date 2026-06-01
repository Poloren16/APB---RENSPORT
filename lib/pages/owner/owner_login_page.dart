import 'package:flutter/material.dart';
import 'package:rensius/theme/app_colors.dart';
import 'package:rensius/pages/admin/admin_dashboard_page.dart';
import 'package:rensius/pages/owner/owner_register_page.dart';
import 'package:rensius/pages/owner/owner_dashboard_page.dart';
import 'package:rensius/data/verification_data.dart';
import 'package:rensius/models/verification_model.dart';
import 'package:rensius/utils/alert_utils.dart';
import 'package:rensius/data/auth_data.dart';
import 'package:rensius/services/supabase_service.dart';
import 'package:rensius/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rensius/services/booking_service.dart';
import 'package:rensius/utils/booking_utils.dart';

class OwnerLoginPage extends StatefulWidget {
  const OwnerLoginPage({super.key});

  @override
  State<OwnerLoginPage> createState() => _OwnerLoginPageState();
}

class _OwnerLoginPageState extends State<OwnerLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _errorMessage;
  bool _isLoading = false;

  void _handleLogin() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Harap masukkan nama pengguna dan kata sandi.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // 1. Dapatkan akun dari local data untuk mencocokkan email
      final localAccount = GlobalAuthData.getAccount(username);
      
      // 2. Jika Supabase aktif dan akun bukan Admin, coba login via Supabase Auth
      if (SupabaseService.isInitialized && 
          localAccount != null && 
          localAccount.role != 'Admin' && 
          localAccount.email.isNotEmpty) {
        try {
          await SupabaseAuthService.signInWithEmail(
            email: localAccount.email,
            password: password,
          );
        } on AuthException catch (e) {
          // Self-healing: Jika password lokal cocok tapi belum terdaftar di Supabase Auth
          if (localAccount.password == password && 
              (e.message.contains('Invalid login credentials') || e.message.contains('invalid_credentials'))) {
            try {
              // Daftarkan ulang ke Supabase Auth secara otomatis
              await SupabaseAuthService.registerEndUser(account: localAccount);
              // Coba masuk kembali
              await SupabaseAuthService.signInWithEmail(
                email: localAccount.email,
                password: password,
              );
            } catch (signUpErr) {
              setState(() {
                _errorMessage = 'Gagal sinkronisasi Supabase Auth: ${signUpErr.toString()}';
                _isLoading = false;
              });
              return;
            }
          } else {
            setState(() {
              _errorMessage = 'Gagal masuk via Supabase: ${e.message}';
              _isLoading = false;
            });
            return;
          }
        } on Object catch (e) {
          // Fallback lokal: Jika password lokal cocok, tetap izinkan masuk secara lokal jika ada kendala koneksi
          if (localAccount.password == password) {
            print('Supabase Auth error, falling back to local offline session: $e');
          } else {
            setState(() {
              _errorMessage = 'Gagal masuk via Supabase: ${e.toString()}';
              _isLoading = false;
            });
            return;
          }
        }
      }

      // 3. Proses login lokal utama
      final account = GlobalAuthData.login(username, password);

      if (account != null) {
        if (account.role == 'Admin') {
          await BookingService.loadBookings(account.username, 'Admin');
          await BookingUtils.loadGlobalBookingsOnline();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
            (route) => false,
          );
        } else if (account.role == 'Owner') {
          await BookingService.loadBookings(account.username, 'Owner');
          await BookingUtils.loadGlobalBookingsOnline();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OwnerDashboardPage(
                username: account.username,
                role: 'Owner',
              ),
            ),
          );
        } else {
          setState(() => _errorMessage = 'Akun ini bukan kategori Pemilik/Admin.');
        }
      } else {
        // Cek apakah ada pengajuan verifikasi pending/rejected untuk username ini
        VerificationRequest? verificationReq;
        for (var r in GlobalVerificationData.requests) {
          if (r.username == username && r.type == 'Owner') {
            verificationReq = r;
            break;
          }
        }
        
        if (verificationReq != null) {
          if (verificationReq.status == 'Pending') {
            AlertUtils.showResultDialog(
              context,
              isSuccess: false,
              title: 'Sedang Diverifikasi',
              message: 'Pendaftaran akun Anda masih dalam proses verifikasi oleh Admin. Mohon tunggu beberapa saat.',
              customIcon: Icons.remove_circle_rounded,
              customColor: Colors.amber,
            );
          } else if (verificationReq.status == 'Rejected') {
            final reason = verificationReq.rejectionReason ?? 'Dokumen KTP kurang jelas/tidak terbaca';
            AlertUtils.showResultDialog(
              context,
              isSuccess: false,
              title: 'Pendaftaran Ditolak',
              message: 'Mohon maaf, pendaftaran Anda ditolak oleh Admin.\n\nAlasan:\n"$reason"\n\nSilakan ketuk OK untuk melakukan pendaftaran ulang dengan berkas yang benar.',
              onConfirm: () {
                Navigator.pop(context); // Tutup dialog hasil
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OwnerRegisterPage()),
                );
              },
            );
          } else {
            setState(() => _errorMessage = 'Nama pengguna atau kata sandi salah.');
          }
        } else {
          setState(() => _errorMessage = 'Nama pengguna atau kata sandi salah.');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const Icon(
                  Icons.business_center_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Portal Pemilik & Admin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kelola venue Anda, verifikasi, dan pengaturan sistem.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextFormField(
                  controller: _usernameController,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                  decoration: const InputDecoration(
                    hintText: 'Nama Pengguna',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                  decoration: InputDecoration(
                    hintText: 'Kata Sandi',
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
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Masuk',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Belum punya akun pemilik?",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OwnerRegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Daftar sebagai Pemilik',
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
