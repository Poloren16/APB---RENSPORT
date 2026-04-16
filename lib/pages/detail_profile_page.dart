import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DetailProfilePage extends StatefulWidget {
  final String username;
  final String email;

  const DetailProfilePage({super.key, required this.username, required this.email});

  @override
  State<DetailProfilePage> createState() => _DetailProfilePageState();
}

class _DetailProfilePageState extends State<DetailProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String initial = widget.username.isNotEmpty ? widget.username[0].toUpperCase() : 'U';

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
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Avatar
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                '${initial}1',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'Detail Personal'),
              Tab(text: 'Akun Sosial Media'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailPersonalTab(),
                const Center(child: Text('Belum ada akun sosial media.', style: TextStyle(color: Colors.grey))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPersonalTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildTextFieldWithLabel('Nama Lengkap *', widget.username),
        const SizedBox(height: 16),
        _buildTextFieldWithLabel('Username *', widget.username.toLowerCase()),
        const SizedBox(height: 16),
        const Text('Jenis Kelamin', style: TextStyle(color: Colors.black54, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Radio(value: 1, groupValue: 0, onChanged: (v){}, activeColor: AppColors.primary),
                    const Text('Laki-laki', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Radio(value: 2, groupValue: 0, onChanged: (v){}, activeColor: AppColors.primary),
                    const Text('Perempuan', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithLabel('Tanggal Lahir', ''),
        const SizedBox(height: 16),
        _buildTextFieldWithLabel('Minat Olahraga', 'Belum ada Kategori Olahraga yang Dipilih', filled: true),
        const SizedBox(height: 16),
        const Text('Bio', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Kamu belum menambahkan keterangan bio..',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithLabel('Email', widget.email, bottomInfo: 'Kamu bisa mengganti emailmu di menu keamanan.'),
        const SizedBox(height: 16),
        _buildPhoneFieldWithLabel('Nomer Telepon', '+62 000 0000 00', bottomInfo: 'Kamu bisa mengganti no HP mu di menu keamanan.'),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTextFieldWithLabel(String label, String hint, {String? bottomInfo, bool filled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label.replaceAll(' *', ''), style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
            if (label.contains('*')) const Text(' *', style: TextStyle(color: Colors.red, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            fillColor: filled ? Colors.grey.shade100 : Colors.white,
            filled: filled,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        if (bottomInfo != null) ...[
          const SizedBox(height: 6),
          Text(
            bottomInfo,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ]
      ],
    );
  }

  Widget _buildPhoneFieldWithLabel(String label, String hint, {String? bottomInfo}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 16,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          Expanded(child: Container(color: Colors.red)),
                          Expanded(child: Container(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (bottomInfo != null) ...[
          const SizedBox(height: 6),
          Text(
            bottomInfo,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ]
      ],
    );
  }
}
