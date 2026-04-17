import 'package:flutter/material.dart';
import 'package:rensius/theme/app_colors.dart';
import 'package:rensius/utils/alert_utils.dart';
import 'package:rensius/pages/owner/owner_login_page.dart';
import 'package:rensius/data/verification_data.dart';
import 'package:rensius/data/auth_data.dart';
import 'package:rensius/models/verification_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class OwnerRegisterPage extends StatefulWidget {
  const OwnerRegisterPage({super.key});

  @override
  State<OwnerRegisterPage> createState() => _OwnerRegisterPageState();
}

class _OwnerRegisterPageState extends State<OwnerRegisterPage> {
  int _currentStep = 0;
  bool _isPasswordVisible = false;
  
  // Controllers Step 1
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  
  // Controllers Step 2
  late TextEditingController _nikController;
  late TextEditingController _npwpController;
  
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _documentUploaded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _nikController = TextEditingController();
    _npwpController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _nikController.dispose();
    _npwpController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty || 
          _emailController.text.isEmpty || 
          _phoneController.text.isEmpty ||
          _usernameController.text.isEmpty ||
          _passwordController.text.isEmpty) {
        _showValidationError('Harap isi semua informasi profil dan akun.');
        return false;
      }
      
      // Check if username exists
      if (GlobalAuthData.usernameExists(_usernameController.text.trim())) {
        _showValidationError('Username sudah digunakan. Silakan cari yang lain.');
        return false;
      }
    } else if (_currentStep == 1) {
      if (_nikController.text.isEmpty || _npwpController.text.isEmpty) {
        _showValidationError('Harap isi nomor NIK dan NPWP dengan benar.');
        return false;
      }
    }
    return true;
  }

  void _showValidationError(String message) {
    AlertUtils.showResultDialog(
      context,
      isSuccess: false,
      title: 'Data Tidak Lengkap',
      message: message,
    );
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _finishRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _documentUploaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        AlertUtils.showToast(context, 'Gagal mengambil gambar.', isSuccess: false);
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Sumber Foto KTP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _finishRegistration() {
    if (!_documentUploaded) {
      AlertUtils.showResultDialog(
        context,
        isSuccess: false,
        title: 'Dokumen Belum Ada',
        message: 'Harap simulasi upload KTP terlebih dahulu.',
      );
      return;
    }

    // 1. Create real request and add to global data
    final newRequest = VerificationRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      applicantName: _nameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      username: _usernameController.text,
      password: _passwordController.text.trim(), // Save for later creation
      nik: _nikController.text,
      npwp: _npwpController.text,
      documentUrl: _imageFile?.path ?? '',
      type: 'Owner',
      submittedAt: DateTime.now(),
    );

    GlobalVerificationData.addRequest(newRequest);

    AlertUtils.showResultDialog(
      context,
      isSuccess: true,
      title: 'Registrasi Berhasil!',
      message: 'Data Anda telah dikirim ke Admin. Harap tunggu verifikasi dalam 1x24 jam.',
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OwnerLoginPage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Daftar Owner Venue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildStepperHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCurrentStepView(),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(0, 'Profil'),
          _buildStepDivider(),
          _buildStepCircle(1, 'Legal'),
          _buildStepDivider(),
          _buildStepCircle(2, 'Upload'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index, String label) {
    bool isActive = _currentStep >= index;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && _currentStep > index
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? AppColors.primary : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 15),
      color: Colors.grey.shade300,
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informasi Profil & Akun', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Lengkapi informasi dasar dan buat akun login Anda.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        _buildTextField(_nameController, 'Nama Lengkap (Sesuai KTP)', Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(_emailController, 'Email Bisnis', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildTextField(_phoneController, 'Nomor WhatsApp', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        const Divider(height: 32),
        _buildTextField(_usernameController, 'Username', Icons.alternate_email_rounded),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Masukkan Password',
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dokumen Legalitas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('NIK dan NPWP diperlukan untuk verifikasi usaha.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        _buildTextField(_nikController, 'Nomor Induk Kependudukan (NIK)', Icons.badge_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildTextField(_npwpController, 'Nomor Pokok Wajib Pajak (NPWP)', Icons.description_outlined, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verifikasi Identitas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Unggah foto KTP asli Anda dengan jelas.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _showImageSourcePicker,
          child: Container(
            width: double.infinity,
            height: 200,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _documentUploaded ? AppColors.primary : Colors.grey.shade300, width: 2),
            ),
            child: _imageFile != null
                ? Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.cover,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Klik untuk Pilih Foto KTP',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Data Anda dijamin aman dengan sistem enkripsi kami dan hanya digunakan untuk verifikasi owner.',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: 'Masukkan $hint',
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_currentStep == 2 ? 'Kirim Verifikasi' : 'Selanjutnya'),
            ),
          ),
        ],
      ),
    );
  }
}
