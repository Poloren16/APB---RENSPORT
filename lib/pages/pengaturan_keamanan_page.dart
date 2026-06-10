import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../utils/alert_utils.dart';
import '../data/auth_data.dart';
import '../data/verification_data.dart';
import '../services/supabase_service.dart';
import '../services/supabase_auth_service.dart';
import 'login_page.dart';

class PengaturanKeamananPage extends StatefulWidget {
  final String username;
  const PengaturanKeamananPage({super.key, required this.username});

  @override
  State<PengaturanKeamananPage> createState() => _PengaturanKeamananPageState();
}

class _PengaturanKeamananPageState extends State<PengaturanKeamananPage> {
  bool isNotifikasiOn = true;
  String selectedLanguage = 'Inggris';
  
  // Real data
  late String currentEmail;
  late String currentPhone;
  String currentPassword = '••••••••••••';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      final acc = GlobalAuthData.getAccount(widget.username);
      currentEmail = (acc?.email != null && acc!.email.isNotEmpty) ? acc.email : 'Belum Diatur';
      currentPhone = (acc?.phoneNumber != null && acc!.phoneNumber.isNotEmpty) ? acc.phoneNumber : 'Belum Diatur';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Keamanan dan Pengaturan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSwitchTile('Notifikasi', Icons.notifications, isNotifikasiOn, (value) {
            setState(() {
              isNotifikasiOn = value;
            });
          }),
          const SizedBox(height: 16),
          // Language removed as requested
          const SizedBox(height: 16),
          _buildItem(
            icon: Icons.email,
            title: 'Email',
            subtitle: currentEmail,
            onTap: _showChangeEmailDialog,
          ),
          const SizedBox(height: 16),
          _buildItem(
            icon: Icons.phone,
            title: 'Nomor Telepon',
            subtitle: currentPhone,
            onTap: _showChangePhoneDialog,
          ),
          const SizedBox(height: 16),
          _buildItem(
            icon: Icons.lock,
            title: 'Ubah Kata Sandi',
            subtitle: currentPassword,
            onTap: _showChangePasswordDialog,
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Hapus Akun',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.red, size: 20),
            onTap: () => _showDeleteAccountConfirmation(),
          ),
        ],
      ),
    );
  }

  // _showLanguagePicker removed as requested

  void _showChangeEmailDialog() {
    final TextEditingController emailController = TextEditingController(text: currentEmail == 'Belum Diatur' ? '' : currentEmail);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: emailController,
            scrollPadding: const EdgeInsets.only(bottom: 200),
            decoration: InputDecoration(
              hintText: 'Email Baru',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await GlobalAuthData.updateAccount(widget.username, newEmail: emailController.text.trim());
                _refreshData();
                if (mounted) Navigator.pop(context);
                AlertUtils.showToast(context, 'Email berhasil diperbarui!', isSuccess: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePhoneDialog() {
    String initialText = currentPhone == 'Belum Diatur' ? '' : currentPhone;
    if (initialText.startsWith('+62')) {
      initialText = initialText.substring(3).trim();
    } else if (initialText.startsWith('62')) {
      initialText = initialText.substring(2).trim();
    }
    final TextEditingController phoneController = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Nomor Telepon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: phoneController,
            scrollPadding: const EdgeInsets.only(bottom: 200),
            decoration: InputDecoration(
              hintText: 'Nomor Telepon Baru',
              prefixText: '+62 ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                String phoneDigits = phoneController.text.trim();
                if (phoneDigits.startsWith('+62')) {
                   phoneDigits = phoneDigits.replaceFirst('+62', '').trim();
                } else if (phoneDigits.startsWith('62')) {
                   phoneDigits = phoneDigits.replaceFirst('62', '').trim();
                } else if (phoneDigits.startsWith('0')) {
                   phoneDigits = phoneDigits.replaceFirst('0', '').trim();
                }
                await GlobalAuthData.updateAccount(widget.username, newPhone: '+62$phoneDigits');
                _refreshData();
                if (mounted) Navigator.pop(context);
                AlertUtils.showToast(context, 'Nomor telepon berhasil diperbarui!', isSuccess: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ubah Kata Sandi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    scrollPadding: const EdgeInsets.only(bottom: 200),
                    decoration: InputDecoration(
                      hintText: 'Kata Sandi Saat Ini',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                    enabled: !isSaving,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    scrollPadding: const EdgeInsets.only(bottom: 200),
                    decoration: InputDecoration(
                      hintText: 'Kata Sandi Baru (Min. 8 karakter)',
                      helperText: '1 kapital, 1 angka, 1 simbol',
                      helperStyle: const TextStyle(fontSize: 9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                    enabled: !isSaving,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final oldPasswordVal = oldPasswordController.text;
                          final passwordVal = passwordController.text;

                          if (oldPasswordVal.isEmpty || passwordVal.isEmpty) {
                            AlertUtils.showToast(context, 'Harap isi semua kolom.', isSuccess: false);
                            return;
                          }

                          final uppercaseRegex = RegExp(r'[A-Z]');
                          final numericRegex = RegExp(r'[0-9]');
                          final symbolRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\\\/\[\]]');

                          if (passwordVal.length < 8 ||
                              !uppercaseRegex.hasMatch(passwordVal) ||
                              !numericRegex.hasMatch(passwordVal) ||
                              !symbolRegex.hasMatch(passwordVal)) {
                            AlertUtils.showToast(context, 'Kata sandi baru harus minimal 8 karakter dan mengandung minimal 1 huruf kapital, 1 angka, dan 1 simbol.', isSuccess: false);
                            return;
                          }

                          final acc = GlobalAuthData.getAccount(widget.username);
                          if (acc == null) {
                            AlertUtils.showToast(context, 'Akun tidak ditemukan.', isSuccess: false);
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            // 1. Verifikasi Kata Sandi Lama
                            if (SupabaseService.isInitialized && acc.role != 'Admin' && acc.email.isNotEmpty) {
                              try {
                                await SupabaseAuthService.signInWithEmail(
                                  email: acc.email,
                                  password: oldPasswordVal,
                                );
                              } on AuthException catch (e) {
                                final msg = e.message.toLowerCase();
                                if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
                                  AlertUtils.showToast(context, 'Kata sandi saat ini salah.', isSuccess: false);
                                } else {
                                  AlertUtils.showToast(
                                    context,
                                    AlertUtils.sanitizeErrorMessage('Gagal memverifikasi kata sandi: ${e.message}'),
                                    isSuccess: false,
                                  );
                                }
                                setDialogState(() {
                                  isSaving = false;
                                });
                                return;
                              } catch (e) {
                                // Fallback ke cek lokal jika terjadi masalah koneksi atau error tak terduga
                                if (acc.password.isNotEmpty && acc.password != oldPasswordVal) {
                                  AlertUtils.showToast(context, 'Kata sandi saat ini salah.', isSuccess: false);
                                  setDialogState(() {
                                    isSaving = false;
                                  });
                                  return;
                                }
                              }
                            } else {
                              // Cek lokal saja untuk Admin atau jika Supabase nonaktif
                              if (acc.password.isNotEmpty && acc.password != oldPasswordVal) {
                                AlertUtils.showToast(context, 'Kata sandi saat ini salah.', isSuccess: false);
                                setDialogState(() {
                                  isSaving = false;
                                });
                                return;
                              }
                            }

                            // 2. Pembaruan di Supabase Auth
                            if (SupabaseService.isInitialized && acc.role != 'Admin' && acc.email.isNotEmpty) {
                              try {
                                await SupabaseAuthService.updatePassword(passwordVal);
                              } on AuthException catch (e) {
                                AlertUtils.showToast(
                                  context,
                                  AlertUtils.sanitizeErrorMessage('Gagal memperbarui di Supabase: ${e.message}'),
                                  isSuccess: false,
                                );
                                setDialogState(() {
                                  isSaving = false;
                                });
                                return;
                              }
                            }

                            // 3. Pembaruan di Cache Lokal
                            await GlobalAuthData.updateAccount(widget.username, newPassword: passwordVal);
                            
                            if (mounted) Navigator.pop(context);
                            AlertUtils.showResultDialog(
                              context,
                              isSuccess: true,
                              title: 'Kata Sandi Diperbarui!',
                              message: 'Kata sandi akun Anda telah berhasil diubah dengan aman.',
                            );
                          } catch (e) {
                            AlertUtils.showToast(context, 'Gagal memperbarui kata sandi. Silakan coba lagi.', isSuccess: false);
                          } finally {
                            if (mounted) {
                              setDialogState(() {
                                isSaving = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text(
            'Apakah Anda yakin ingin menghapus akun ini? Tindakan ini tidak dapat dibatalkan dan semua data Anda akan dihapus secara permanen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                // 1. Sync with verification records
                final reqIndex = GlobalVerificationData.requests.indexWhere((r) => r.username == widget.username);
                if (reqIndex != -1) {
                  await GlobalVerificationData.updateRequestStatus(
                    GlobalVerificationData.requests[reqIndex].id, 
                    'Rejected', 
                    reason: 'Akun dihapus oleh pengguna'
                  );
                }
                
                // 2. Delete the account
                await GlobalAuthData.deleteAccount(widget.username);
                
                if (mounted) {
                  // Pop dialog
                  Navigator.pop(context);
                  // Return to login
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                  AlertUtils.showToast(context, 'Akun berhasil dihapus.', isSuccess: true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus Permanen', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: AppColors.primary,
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
