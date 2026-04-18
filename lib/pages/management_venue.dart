import 'package:flutter/material.dart';
import 'package:rensius/theme/app_colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rensius/data/venue_data.dart';
import 'package:rensius/utils/alert_utils.dart';

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
        label: const Text('Tambah Venue', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatsRow() {
    int activeVenues = _venues.where((v) => v['status'] == 'Active').length;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Venue',
            value: _venues.length.toString(),
            icon: Icons.sports_soccer,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Daftar Aktif',
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
                    isEditing ? 'Edit Venue' : 'Tambah Venue Baru',
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
                        label: 'Nama Venue',
                        icon: Icons.stadium,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: locationController,
                        label: 'Lokasi',
                        icon: Icons.location_on,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: IconButton(
                            icon: const Icon(
                              Icons.my_location,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Pilih dari Peta',
                            onPressed: () async {
                              // Navigate to Map page (Simulation) and wait for result
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MapPickerPage(),
                                ),
                              );

                              // If user selects location, fill automatically to controller
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
                        label: 'Tipe Olahraga (misal: Futsal)',
                        icon: Icons.sports_soccer,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        controller: priceController,
                        label: 'Harga (misal: IDR 100,000 / Jam)',
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
                          'Jam Tersedia',
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
                    'Batal',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate minimal form filled
                    if (nameController.text.trim().isEmpty ||
                        locationController.text.trim().isEmpty) {
                      AlertUtils.showResultDialog(
                        context,
                        isSuccess: false,
                        title: 'Form Belum Lengkap!',
                        message: 'Nama Venue dan Lokasi wajib diisi.',
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
                          ? '"${nameController.text.trim()}" berhasil diupdate.'
                          : '"${nameController.text.trim()}" sekarang tersedia di daftar venue Anda.',
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
                    'Simpan',
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

  // Delete Confirmation Dialog
  void _confirmDelete(int index) {
    final venueName = _venues[index]['name'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Venue'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$venueName"? \nTindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
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
                  title: 'Terhapus!',
                  message: '"$venueName" berhasil dihapus dari sistem.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- GOOGLE MAPS SIMULATION PAGE ---
// This page acts as a location picker that returns a string to the previous page.
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng _selectedLocation = const LatLng(-6.2088, 106.8456); // Default Jakarta
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedLocation,
        draggable: true,
        onDragEnd: (newPosition) {
          setState(() {
            _selectedLocation = newPosition;
          });
        },
      ),
    );
  }

  void _onTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
            });
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pilih Lokasi Venue',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 12,
            ),
            onMapCreated: (controller) {},
            onTap: _onTap,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap on the map or drag the marker to set your venue location.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // Simulate an address for the coordinates because we don't have Geocoding API keys
                  final String simulatedAddress = 
                    'Location (${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)})';
                  
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Konfirmasi Lokasi'),
                      content: Text('Apakah Anda ingin menggunakan koordinat ini untuk venue Anda?\n\n$simulatedAddress'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context, simulatedAddress);
                          },
                          child: const Text('Pilih'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Gunakan Lokasi Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
