import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/alert_utils.dart';
import '../data/auth_data.dart';
import '../data/verification_data.dart';
import '../utils/validation_utils.dart';
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
    final account = GlobalAuthData.getAccount(widget.username);
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
    String displayPhone = currentPhone == 'Belum Diatur' ? '' : currentPhone;
    if (displayPhone.startsWith('+62')) {
      displayPhone = displayPhone.replaceFirst('+62', '').trim();
    }
    final TextEditingController phoneController = TextEditingController(text: displayPhone);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Nomor Telepon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: phoneController,
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
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Kata Sandi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: passwordController,
            decoration: InputDecoration(
              hintText: 'Kata Sandi Baru',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final passwordError = ValidationUtils.validatePassword(passwordController.text);
                if (passwordError != null) {
                  AlertUtils.showToast(context, passwordError, isSuccess: false);
                  return;
                }
                await GlobalAuthData.updateAccount(widget.username, newPassword: passwordController.text);
                if (mounted) Navigator.pop(context);
                AlertUtils.showResultDialog(
                  context,
                  isSuccess: true,
                  title: 'Kata Sandi Diperbarui!',
                  message: 'Kata sandi akun Anda telah berhasil diubah dengan aman.',
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
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
