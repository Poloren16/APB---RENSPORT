import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/alert_utils.dart';
import '../data/auth_data.dart';

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
      currentEmail = account?.email ?? 'Belum Diatur';
      currentPhone = account?.phoneNumber ?? 'Belum Diatur';
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
            onTap: () async {
              // Add confirmation dialog if needed
            },
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
    final TextEditingController phoneController = TextEditingController(text: currentPhone == 'Belum Diatur' ? '' : currentPhone);
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
                if (passwordController.text.length < 6) {
                  AlertUtils.showToast(context, 'Kata sandi harus minimal 6 karakter', isSuccess: false);
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
