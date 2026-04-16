import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/venue_data.dart';
import '../utils/alert_utils.dart';

class ManagementVenuePage extends StatefulWidget {
  const ManagementVenuePage({super.key});

  @override
  State<ManagementVenuePage> createState() => _ManagementVenuePageState();
}

class _ManagementVenuePageState extends State<ManagementVenuePage> {
  // Use global data for venues
  List<Map<String, dynamic>> get _venues => GlobalVenueData.venues;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Venue Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          // Membatasi lebar konten maksimal agar rapi di Desktop & Web (Responsif)
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  const Text(
                    'Your Venues',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildVenueList(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVenueDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Venue', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatsRow() {
    int activeVenues = _venues.where((v) => v['status'] == 'Active').length;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Venues',
            value: _venues.length.toString(),
            icon: Icons.sports_soccer,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Active Listings',
            value: activeVenues.toString(),
            icon: Icons.check_circle_outline,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueList() {
    // Menggunakan LayoutBuilder agar responsif (1 kolom di HP, 2 kolom di Web/Desktop)
    return LayoutBuilder(
      builder: (context, constraints) {
        // Jika layar cukup lebar (misal > 600px), gunakan GridView
        if (constraints.maxWidth > 600) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5, // Rasio aspek disesuaikan
            ),
            itemCount: _venues.length,
            itemBuilder: (context, index) => _buildVenueCard(index),
          );
        } else {
          // Tampilan mobile menggunakan ListView
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _venues.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildVenueCard(index),
              );
            },
          );
        }
      },
    );
  }

  // Diekstrak menjadi fungsi terpisah agar dapat dipakai oleh GridView maupun ListView
  Widget _buildVenueCard(int index) {
    final venue = _venues[index];
    final isActive = venue['status'] == 'Active';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon / Avatar for venue
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.stadium, color: AppColors.primary, size: 30),
              ),
            ),
            const SizedBox(width: 16),
            // Venue Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    venue['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue['location'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${venue['type']} • ${venue['price']}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accent.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      venue['status'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? AppColors.accent : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons (Edit / Delete)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                  onPressed: () => _showVenueDialog(venue: venue, index: index),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDelete(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI CRUD (TAMBAH, EDIT, HAPUS) ---

  // Dialog untuk Tambah dan Edit Venue
  void _showVenueDialog({Map<String, dynamic>? venue, int? index}) {
    final isEditing = venue != null && index != null;

    final nameController = TextEditingController(text: venue?['name'] ?? '');
    final locationController = TextEditingController(
      text: venue?['location'] ?? '',
    );
    final typeController = TextEditingController(text: venue?['type'] ?? '');
    final priceController = TextEditingController(text: venue?['price'] ?? '');
    // Status Dropdown default
    String selectedStatus = venue?['status'] ?? 'Active';

    // Extract existing schedules
    Set<String> selectedSchedules = {};
    if (isEditing &&
        venue?['courts'] != null &&
        (venue!['courts'] as List).isNotEmpty) {
      final firstCourt = (venue['courts'] as List)[0];
      if (firstCourt['schedules'] != null) {
        for (var schedule in firstCourt['schedules']) {
          if (schedule['isAvailable'] == true) {
            selectedSchedules.add(schedule['time']);
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.add_circle_outline,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Edit Venue' : 'Add New Venue',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400, // Tampilan konsisten utamanya di web/desktop
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      _buildDialogTextField(
                        controller: nameController,
                        label: 'Venue Name',
                        icon: Icons.stadium,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: locationController,
                        label: 'Location',
                        icon: Icons.location_on,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: IconButton(
                            icon: const Icon(
                              Icons.my_location,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Pilih dari Map',
                            onPressed: () async {
                              // Navigasi ke halaman Map (Simulasi) dan tunggu hasilnya
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MapPickerPage(),
                                ),
                              );

                              // Jika user memilih lokasi, isi otomatis ke controller
                              if (result != null && result is String) {
                                locationController.text = result;
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: typeController,
                        label: 'Sport Type (e.g. Futsal)',
                        icon: Icons.sports_soccer,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: priceController,
                        label: 'Price (e.g. Rp 100.000 / Jam)',
                        icon: Icons.payments,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          prefixIcon: const Icon(
                            Icons.info_outline,
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        items: ['Active', 'Maintenance', 'Inactive']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedStatus = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Available Hours',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          '08:00',
                          '10:00',
                          '12:00',
                          '14:00',
                          '16:00',
                          '18:00',
                          '20:00',
                          '22:00'
                        ].map((time) {
                          final isSelected = selectedSchedules.contains(time);
                          return FilterChip(
                            label: Text(time),
                            selected: isSelected,
                            selectedColor: AppColors.secondary,
                            checkmarkColor: AppColors.primary,
                            onSelected: (bool selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedSchedules.add(time);
                                } else {
                                  selectedSchedules.remove(time);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validasi minimal form terisi
                    if (nameController.text.trim().isEmpty ||
                        locationController.text.trim().isEmpty) {
                      AlertUtils.showResultDialog(
                        context,
                        isSuccess: false,
                        title: 'Form Belum Lengkap!',
                        message: 'Nama Venue dan Lokasi wajib diisi untuk melanjutkan.',
                      );
                      return;
                    }

                    // Create or update courts
                    List<Map<String, dynamic>> updatedCourts = [];
                    if (isEditing && venue!['courts'] != null) {
                      updatedCourts =
                          List<Map<String, dynamic>>.from(venue['courts']);
                    }

                    if (updatedCourts.isEmpty) {
                      updatedCourts.add({
                        'name': '${nameController.text.trim()} Main Court',
                        'size': 'P Minimal X L Minimal', // dummy size
                        'schedules': []
                      });
                    }

                    updatedCourts[0]['name'] =
                        '${nameController.text.trim()} Main Court';
                    updatedCourts[0]['schedules'] = [
                      '08:00',
                      '10:00',
                      '12:00',
                      '14:00',
                      '16:00',
                      '18:00',
                      '20:00',
                      '22:00'
                    ]
                        .map((time) => {
                              'time': time,
                              'isAvailable': selectedSchedules.contains(time)
                            })
                        .toList();

                    final newVenue = {
                      'name': nameController.text.trim(),
                      'location': locationController.text.trim(),
                      'type': typeController.text.trim(),
                      'price': priceController.text.trim(),
                      'status': selectedStatus,
                      'courts': updatedCourts,
                    };

                    setState(() {
                      if (isEditing) {
                        _venues[index] = newVenue;
                      } else {
                        _venues.add(newVenue);
                      }
                    });

                    Navigator.pop(context);

                    AlertUtils.showResultDialog(
                      context,
                      isSuccess: true,
                      title: isEditing ? 'Update Berhasil!' : 'Venue Ditambahkan!',
                      message: isEditing
                          ? '"${nameController.text.trim()}" telah berhasil diperbarui.'
                          : '"${nameController.text.trim()}" kini tersedia dalam daftar venue Anda.',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  // Dialog Konfirmasi Hapus
  void _confirmDelete(int index) {
    final venueName = _venues[index]['name'];
    // ... dialog code remains same
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Venue'),
          content: Text(
            'Are you sure you want to delete "$venueName"? \nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _venues.removeAt(index);
                });
                Navigator.pop(context);
                AlertUtils.showResultDialog(
                  context,
                  isSuccess: true,
                  title: 'Dihapus!',
                  message: '"$venueName" telah berhasil dihapus dari sistem.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- HALAMAN SIMULASI GOOGLE MAPS ---
// Halaman ini bertindak sebagai pemilih lokasi yang akan mengembalikan string ke halaman sebelumnya.
class MapPickerPage extends StatelessWidget {
  const MapPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pilih Lokasi (Khusus Indonesia)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background - Menggambarkan UI "Peta"
          Container(
            color: const Color(0xFF81D4FA), // Warna biru laut
            child: Stack(
              children: [
                // Gambar Asli Peta Topografi Indonesia dari Wikimedia Commons
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Opacity(
                    opacity: 0.85,
                    child: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Indonesia_relief_location_map.jpg/1024px-Indonesia_relief_location_map.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'Gagal memuat gambar peta.\nPastikan Anda terhubung ke internet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Grid pattern for map feel
                CustomPaint(size: Size.infinite, painter: GridPainter()),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 90,
                        color: Colors.black.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Peta Satelit: INDONESIA',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '(Terbatas hanya untuk wilayah Indonesia)',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Area yang bisa di-klik untuk memilih koordinat lokasi
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (TapDownDetails details) {
                // Saat user melakukan klik/tap di layar peta, generate coordinate location
                final int mockX = details.localPosition.dx.toInt();
                final int mockY = details.localPosition.dy.toInt();

                // Menyimulasikan pembatasan koordinat hanya se-Indonesia
                // (Membagi wilayah berdasarkan koordinat X di layar)
                String region = 'Jakarta';
                String province = 'DKI Jakarta';

                if (mockX < 100) {
                  region = 'Medan';
                  province = 'Sumatera Utara';
                } else if (mockX > 300) {
                  region = 'Makassar';
                  province = 'Sulawesi Selatan';
                } else if (mockY < 200) {
                  region = 'Pontianak';
                  province = 'Kalimantan Barat';
                } else if (mockY > 500) {
                  region = 'Denpasar';
                  province = 'Bali';
                } else {
                  region = 'Bandung';
                  province = 'Jawa Barat';
                }

                final String generatedAddress =
                    'Jl. Sudirman No. $mockX, $region, $province, Indonesia';

                // Konfirmasi Lokasi
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Row(
                      children: const [
                        Icon(Icons.location_on, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Konfirmasi Titik Peta'),
                      ],
                    ),
                    content: Text(
                      'Apakah Anda yakin memilih lokasi ini?\n\nAlamat:\n$generatedAddress',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx); // Tutup dialog konfirmasi
                          Navigator.pop(
                            context,
                            generatedAddress,
                          ); // Kembali ke halaman utama dengan membawa data lokasi
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Pilih Lokasi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Petunjuk
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.touch_app, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sistem Manajemen Venue ini dibatasi hanya untuk wilayah operasi Indonesia. Tap pada layar untuk memilih titik/provinsi Anda.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.1)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
