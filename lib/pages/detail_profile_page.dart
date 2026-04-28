import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../data/auth_data.dart';
import '../data/verification_data.dart';
import '../utils/alert_utils.dart';
import 'pengaturan_keamanan_page.dart';

class DetailProfilePage extends StatefulWidget {
  final String username;
  final String email;
  final String role;

  const DetailProfilePage({
    super.key, 
    required this.username, 
    required this.email,
    required this.role,
  });

  @override
  State<DetailProfilePage> createState() => _DetailProfilePageState();
}

class _DetailProfilePageState extends State<DetailProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _instaController;
  late TextEditingController _twitterController;
  late TextEditingController _fbController;
  
  String? _profileImagePath;
  String _gender = 'Belum Diatur';
  String _dob = '';
  List<String> _selectedSports = [];

  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _sportsOptions = [
    {'name': 'Mini Soccer', 'icon': Icons.sports_soccer_outlined},
    {'name': 'Basketball', 'icon': Icons.sports_basketball_outlined},
    {'name': 'Tennis', 'icon': Icons.sports_tennis_outlined},
    {'name': 'Badminton', 'icon': Icons.sports_tennis_rounded}, 
    {'name': 'Soccer', 'icon': Icons.sports_soccer},
    {'name': 'Volleyball', 'icon': Icons.sports_volleyball_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final account = GlobalAuthData.getAccount(widget.username);
    _nameController = TextEditingController(text: account?.applicantName ?? widget.username);
    _bioController = TextEditingController(text: account?.bio ?? "");
    _instaController = TextEditingController(text: account?.instagram ?? "");
    _twitterController = TextEditingController(text: account?.twitter ?? "");
    _fbController = TextEditingController(text: account?.facebook ?? "");
    _selectedSports = List<String>.from(account?.sportsInterests ?? []);
    _profileImagePath = account?.profileImagePath;
    _gender = account?.gender ?? 'Belum Diatur';
    _dob = account?.dateOfBirth ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _instaController.dispose();
    _twitterController.dispose();
    _fbController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_isEditing) return;
    
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });
    }
  }

  void _showImageSourceDialog() {
    if (!_isEditing) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih Sumber Foto Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  bool _validateSocialUrls() {
    final insta = _instaController.text.trim();
    if (insta.isNotEmpty && !insta.startsWith('@') && !insta.contains('instagram.com')) {
      AlertUtils.showToast(context, 'Please enter a valid Instagram handle or URL', isSuccess: false);
      return false;
    }
    return true;
  }

  Future<void> _saveProfile() async {
    if (!_validateSocialUrls()) return;

    await GlobalAuthData.updateAccount(
      widget.username,
      newName: _nameController.text.trim(),
      newBio: _bioController.text.trim(),
      newSports: _selectedSports,
      newInsta: _instaController.text.trim(),
      newTwitter: _twitterController.text.trim(),
      newFacebook: _fbController.text.trim(),
      newProfileImage: _profileImagePath,
      newGender: _gender,
      newDOB: _dob,
    );
    
    if (mounted) {
      AlertUtils.showToast(context, 'Profil berhasil diupdate!', isSuccess: true);
      setState(() => _isEditing = false);
    }
  }

  Future<void> _selectDate() async {
    if (!_isEditing) return;

    DateTime initialDate = _dob.isNotEmpty ? DateTime.parse(_dob) : DateTime(2000, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dob = picked.toString().split(' ')[0];
      });
    }
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
          'Profil',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey, size: 22),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildAvatarSection(),
                          const SizedBox(height: 24),
                          _buildTabSection(),
                        ],
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailPersonalTab(),
                    _buildSocialMediaTab(),
                  ],
                ),
              ),
            ),
          ),
          if (_isEditing) _buildBottomSaveButton(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                image: _profileImagePath != null 
                    ? DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(_profileImagePath!) as ImageProvider
                            : FileImage(File(_profileImagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: _profileImagePath == null 
                  ? Text(
                      _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null,
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                  child: const Icon(Icons.camera_alt, size: 20, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.black87,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppColors.primary,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      tabs: const [
        Tab(text: 'Detail Pribadi'),
        Tab(text: 'Akun Media Sosial'),
      ],
    );
  }

  Widget _buildDetailPersonalTab() {
    final account = GlobalAuthData.getAccount(widget.username);
    final emailVal = account?.email ?? '';
    final phoneVal = account?.phoneNumber ?? '';
    final userEmail = emailVal.isNotEmpty ? emailVal : widget.email;
    final userPhone = phoneVal.isNotEmpty ? phoneVal : '+62 812 3456 7890';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextFieldWithLabel('Nama Lengkap *', _nameController, isReadOnly: !_isEditing),
          const SizedBox(height: 20),
          _buildStaticField('Username *', widget.username),
          const SizedBox(height: 20),
          
          const Text('Jenis Kelamin', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildGenderOption('Laki-laki', Icons.male),
              const SizedBox(width: 16),
              _buildGenderOption('Perempuan', Icons.female),
            ],
          ),
          
          const SizedBox(height: 20),
          _buildClickableField('Tanggal Lahir', _dob.isEmpty ? 'Pilih Tanggal' : _dob, Icons.calendar_today, _selectDate),
          
          if (widget.role.toLowerCase() != 'owner') ...[
            const SizedBox(height: 24),
            const Text('Minat Olahraga',
                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSportsGrid(),
          ],
          
          const SizedBox(height: 24),
          const Text('Bio', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _bioController,
            maxLines: 4,
            readOnly: !_isEditing,
            decoration: InputDecoration(
              hintText: "Anda belum menambahkan bio..",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _isEditing ? AppColors.primary : Colors.grey.shade300),
              ),
            ),
          ),
          
        _buildStaticField(
          'Email', 
          userEmail, 
          color: Colors.grey,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PengaturanKeamananPage(username: widget.username)),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildStaticField(
          'Nomor Telepon', 
          userPhone, 
          color: Colors.grey,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PengaturanKeamananPage(username: widget.username)),
            );
          },
        ),

        // KTP Section for Owner
        if (widget.role.toLowerCase() == 'owner') ...[
          const SizedBox(height: 24),
          const Text('Foto KTP / Identitas', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final reqs = GlobalVerificationData.requests
                .where((r) => r.type == 'Owner' && 
                    (r.username?.toLowerCase() == widget.username.toLowerCase() || 
                     r.email.toLowerCase() == widget.email.toLowerCase()))
                .toList();
            final documentUrl = reqs.isNotEmpty ? reqs.first.documentUrl : '';
            return Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: documentUrl.isNotEmpty && (documentUrl.contains('/') || documentUrl.contains('\\'))
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(documentUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  Text('Foto tidak dapat ditampilkan', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ]),
                              ))
                          : Image.file(File(documentUrl), fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  Text('Foto tidak dapat ditampilkan', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ]),
                              )),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.badge_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Foto KTP belum diunggah', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
            );
          }),
        ],
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, IconData icon) {
    bool isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_isEditing) setState(() => _gender = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(value, style: TextStyle(color: isSelected ? AppColors.primary : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClickableField(String label, String value, IconData icon, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: _isEditing ? AppColors.primary : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 15)),
                Icon(icon, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSportsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 64,
      ),
      itemCount: _sportsOptions.length,
      itemBuilder: (context, index) {
        final option = _sportsOptions[index];
        bool isSelected = _selectedSports.contains(option['name']);
        return GestureDetector(
          onTap: () {
            if (_isEditing) {
              setState(() {
                if (isSelected) {
                  _selectedSports.remove(option['name']);
                } else {
                  _selectedSports.add(option['name']);
                }
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
              boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 4)] : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(option['icon'], color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.6), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSocialField('Instagram', _instaController, Icons.camera_alt, Colors.pink),
          const SizedBox(height: 20),
          _buildSocialField('Twitter (X)', _twitterController, Icons.close, Colors.black),
          const SizedBox(height: 20),
          _buildSocialField('Facebook', _fbController, Icons.facebook, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSocialField(String label, TextEditingController controller, IconData icon, Color iconColor) {
    Widget prefixIcon = Icon(icon, color: iconColor);
    if (label == 'Instagram') {
      prefixIcon = ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.purple, Colors.pink, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Icon(icon, color: Colors.white),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: !_isEditing,
          decoration: InputDecoration(
            hintText: 'Link or username',
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _isEditing ? AppColors.primary : Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldWithLabel(String label, TextEditingController controller, {bool isReadOnly = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          decoration: InputDecoration(
            hintText: controller.text,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _isEditing ? AppColors.primary : Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticField(String label, String value, {Color? color, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50, 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value, 
                    style: TextStyle(color: color ?? Colors.black87, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
