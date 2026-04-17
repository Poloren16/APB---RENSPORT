import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/alert_utils.dart';

class PengaturanKeamananPage extends StatefulWidget {
  final String email;
  const PengaturanKeamananPage({super.key, required this.email});

  @override
  State<PengaturanKeamananPage> createState() => _PengaturanKeamananPageState();
}

class _PengaturanKeamananPageState extends State<PengaturanKeamananPage> {
  bool isNotifikasiOn = true;
  String selectedLanguage = 'Indonesia';
  late String currentEmail;
  String currentPhone = '+62000000000';
  String currentPassword = '••••••••••••';

  @override
  void initState() {
    super.initState();
    currentEmail = widget.email;
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
          'Security and Settings',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSwitchTile('Notifications', Icons.notifications, isNotifikasiOn, (value) {
            setState(() {
              isNotifikasiOn = value;
            });
          }),
          const SizedBox(height: 16),
          _buildItem(
            icon: Icons.flag,
            title: 'Language',
            subtitle: selectedLanguage,
            onTap: _showLanguagePicker,
            iconColor: Colors.red,
          ),
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
            title: 'Phone Number',
            subtitle: currentPhone,
            onTap: _showChangePhoneDialog,
          ),
          const SizedBox(height: 16),
          _buildItem(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: currentPassword,
            onTap: _showChangePasswordDialog,
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.red, size: 20),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Indonesia'),
                trailing: selectedLanguage == 'Indonesia' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => selectedLanguage = 'Indonesia');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('English'),
                trailing: selectedLanguage == 'English' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => selectedLanguage = 'English');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangeEmailDialog() {
    final TextEditingController emailController = TextEditingController(text: currentEmail);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: 'New Email',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => currentEmail = emailController.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePhoneDialog() {
    final TextEditingController phoneController = TextEditingController(text: currentPhone);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Phone Number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: phoneController,
            decoration: InputDecoration(
              hintText: 'New Phone Number',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => currentPhone = phoneController.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
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
          title: const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: passwordController,
            decoration: InputDecoration(
              hintText: 'New Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  setState(() => currentPassword = '••••••••••••');
                }
                Navigator.pop(context);
                AlertUtils.showResultDialog(
                  context,
                  isSuccess: true,
                  title: 'Password Updated!',
                  message: 'Your account password has been successfully changed securely.',
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade400),
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
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade400),
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
