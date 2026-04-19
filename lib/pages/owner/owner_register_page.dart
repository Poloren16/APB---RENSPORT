import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  String _selectedCountryCode = '+62';
  final List<String> _countryCodes = ['+62', '+1', '+60', '+65', '+44', '+81'];
  
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
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final user = _usernameController.text.trim();
      final pass = _passwordController.text.trim();

      if (name.isEmpty || email.isEmpty || phone.isEmpty || user.isEmpty || pass.isEmpty) {
        _showValidationError('Harap isi semua informasi profil dan akun.');
        return false;
      }

      // Email Validation
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        _showValidationError('Harap masukkan alamat email bisnis yang valid (contoh: nama@perusahaan.com).');
        return false;
      }

      // Phone Validation (Numbers only)
      final phoneRegex = RegExp(r'^[0-9]{7,15}$');
      if (!phoneRegex.hasMatch(phone)) {
        _showValidationError('Nomor telepon hanya boleh berisi angka (7-15 digit).');
        return false;
      }
      
      // Check if username exists
      if (GlobalAuthData.usernameExists(user)) {
        _showValidationError('Nama pengguna ini sudah digunakan. Silakan pilih yang lain.');
        return false;
      }
      
      if (pass.length < 6) {
        _showValidationError('Kata sandi harus minimal 6 karakter.');
        return false;
      }

    } else if (_currentStep == 1) {
      final nik = _nikController.text.trim();
      final npwp = _npwpController.text.trim();

      if (nik.isEmpty || npwp.isEmpty) {
        _showValidationError('Harap isi kolom NIK dan NPWP.');
        return false;
      }

      // NIK Validation (16 digits)
      if (!RegExp(r'^[0-9]{16}$').hasMatch(nik)) {
        _showValidationError('NIK harus tepat 16 digit angka.');
        return false;
      }

      // NPWP Validation (15 digits)
      if (!RegExp(r'^[0-9]{15}$').hasMatch(npwp)) {
        _showValidationError('NPWP harus tepat 15 digit angka.');
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
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _imageFile = image;
        _documentUploaded = true;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih Sumber Foto ID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(Icons.camera_alt, 'Kamera', () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  }),
                  _buildSourceOption(Icons.photo_library, 'Galeri', () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _finishRegistration() async {
    if (!_documentUploaded) {
      AlertUtils.showResultDialog(
        context,
        isSuccess: false,
        title: 'Dokumen Kurang',
        message: 'Harap unggah foto KTP Anda terlebih dahulu.',
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

    await GlobalVerificationData.addRequest(newRequest);

    AlertUtils.showResultDialog(
      context,
      isSuccess: true,
      title: 'Pendaftaran Berhasil',
      message: 'Data Anda telah dikirim ke Admin. Mohon tunggu verifikasi dalam waktu 24 jam.',
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
        title: const Text('Pendaftaran Pemilik', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          _buildStepCircle(2, 'Identitas'),
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
        const Text('Lengkapi informasi dasar Anda dan buat akun login.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        _buildTextField(_nameController, 'Nama Lengkap (Sesuai KTP)', Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(_emailController, 'Email Bisnis', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildPhoneField(),
        const SizedBox(height: 16),
        const Divider(height: 32),
        _buildTextField(_usernameController, 'Nama Pengguna', Icons.alternate_email_rounded),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WhatsApp Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '812-3456-7890',
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

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Masukkan Kata Sandi',
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
        const Text('Dokumen Legal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('NIK dan NPWP diperlukan untuk verifikasi bisnis.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        _buildTextField(_nikController, 'Nomor Identitas (NIK)', Icons.badge_outlined, keyboardType: TextInputType.number),
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
        const Text('Unggah foto KTP asli Anda yang terbaca jelas.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _showImageSourceDialog,
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
                ? (kIsWeb 
                    ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                    : Image.file(File(_imageFile!.path), fit: BoxFit.cover))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: _documentUploaded ? AppColors.primary : Colors.grey,
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
                  'Data Anda dijamin aman dengan sistem enkripsi kami dan hanya digunakan untuk verifikasi pemilik.',
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
              child: Text(_currentStep == 2 ? 'Kirim Verifikasi' : 'Lanjut'),
            ),
          ),
        ],
      ),
    );
  }
}
