import 'package:flutter/material.dart';
import 'dart:io' as io;
import '../../theme/app_colors.dart';
import '../../data/venue_data.dart';
import '../../data/verification_data.dart';
import '../../data/auth_data.dart';
import '../../models/verification_model.dart';
import '../../utils/alert_utils.dart';
import 'map_picker_page.dart';
import 'package:image_picker/image_picker.dart';

class AddVenuePage extends StatefulWidget {
  final Map<String, dynamic>? venueToEdit;
  final int? index;

  const AddVenuePage({super.key, this.venueToEdit, this.index});

  @override
  State<AddVenuePage> createState() => _AddVenuePageState();
}

class _AddVenuePageState extends State<AddVenuePage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _provinsiController;
  late TextEditingController _kotaController;
  late TextEditingController _jalanController;
  late TextEditingController _dllController;
  String? _selectedProvinsi;
  String? _selectedKota;
  
  static const List<String> _facilitiesOptions = ['Kamar Mandi', 'Parkiran', 'Kantin', 'Mushola', 'Locker Room'];
  static const List<String> _courtTypeOptions = ['Indoor', 'Outdoor'];
  static const List<String> _floorTypeOptions = ['Vinyl', 'Rumput Sintetis', 'Semen', 'Parquet', 'Karpet'];
  static const List<String> _timeOptions = ['06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00'];
  static const List<String> _daysOfWeek = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  // Data Provinsi & Kota Indonesia
  static const Map<String, List<String>> _provinceCityData = {
    'Aceh': ['Banda Aceh', 'Lhokseumawe', 'Langsa', 'Sabang', 'Subulussalam'],
    'Sumatera Utara': ['Medan', 'Pematangsiantar', 'Binjai', 'Tebing Tinggi', 'Tanjungbalai'],
    'Sumatera Barat': ['Padang', 'Bukittinggi', 'Payakumbuh', 'Pariaman', 'Solok'],
    'Riau': ['Pekanbaru', 'Dumai', 'Siak', 'Bengkalis', 'Kampar'],
    'Kepulauan Riau': ['Tanjungpinang', 'Batam', 'Bintan', 'Karimun', 'Natuna'],
    'Jambi': ['Jambi', 'Sungai Penuh', 'Muaro Bungo', 'Tebo', 'Merangin'],
    'Sumatera Selatan': ['Palembang', 'Lubuklinggau', 'Prabumulih', 'Pagaralam', 'Baturaja'],
    'Bangka Belitung': ['Pangkalpinang', 'Bangka', 'Belitung', 'Bangka Tengah', 'Bangka Barat'],
    'Bengkulu': ['Bengkulu', 'Kepahiang', 'Rejang Lebong', 'Lebong', 'Muko Muko'],
    'Lampung': ['Bandar Lampung', 'Metro', 'Pringsewu', 'Kota Agung', 'Liwa'],
    'Banten': ['Serang', 'Tangerang', 'Tangerang Selatan', 'Cilegon', 'Lebak'],
    'DKI Jakarta': ['Jakarta Pusat', 'Jakarta Utara', 'Jakarta Barat', 'Jakarta Selatan', 'Jakarta Timur', 'Kepulauan Seribu'],
    'Jawa Barat': ['Bandung', 'Bekasi', 'Bogor', 'Cimahi', 'Cirebon', 'Depok', 'Sukabumi', 'Tasikmalaya'],
    'Jawa Tengah': ['Semarang', 'Solo', 'Magelang', 'Pekalongan', 'Salatiga', 'Tegal', 'Purwokerto'],
    'DI Yogyakarta': ['Yogyakarta', 'Sleman', 'Bantul', 'Kulonprogo', 'Gunungkidul'],
    'Jawa Timur': ['Surabaya', 'Malang', 'Kediri', 'Blitar', 'Madiun', 'Mojokerto', 'Pasuruan', 'Probolinggo'],
    'Bali': ['Denpasar', 'Gianyar', 'Tabanan', 'Badung', 'Buleleng', 'Klungkung'],
    'Nusa Tenggara Barat': ['Mataram', 'Bima', 'Sumbawa', 'Dompu', 'Lombok Timur'],
    'Nusa Tenggara Timur': ['Kupang', 'Ende', 'Maumere', 'Ruteng', 'Waingapu'],
    'Kalimantan Barat': ['Pontianak', 'Singkawang', 'Sanggau', 'Sintang', 'Ketapang'],
    'Kalimantan Tengah': ['Palangka Raya', 'Sampit', 'Pangkalan Bun', 'Kuala Kapuas', 'Buntok'],
    'Kalimantan Selatan': ['Banjarmasin', 'Banjarbaru', 'Martapura', 'Pelaihari', 'Amuntai'],
    'Kalimantan Timur': ['Samarinda', 'Balikpapan', 'Bontang', 'Sangatta', 'Tenggarong'],
    'Kalimantan Utara': ['Tanjung Selor', 'Tarakan', 'Nunukan', 'Malinau', 'Bulungan'],
    'Sulawesi Utara': ['Manado', 'Bitung', 'Tomohon', 'Kotamobagu', 'Tondano'],
    'Gorontalo': ['Gorontalo', 'Limboto', 'Kwandang', 'Atinggola', 'Marisa'],
    'Sulawesi Tengah': ['Palu', 'Luwuk', 'Poso', 'Buol', 'Parigi'],
    'Sulawesi Barat': ['Mamuju', 'Majene', 'Polewali', 'Pasangkayu', 'Mamasa'],
    'Sulawesi Selatan': ['Makassar', 'Parepare', 'Palopo', 'Bone', 'Gowa'],
    'Sulawesi Tenggara': ['Kendari', 'Bau-Bau', 'Kolaka', 'Muna', 'Konawe'],
    'Maluku': ['Ambon', 'Tual', 'Masohi', 'Namlea', 'Saumlaki'],
    'Maluku Utara': ['Sofifi', 'Ternate', 'Tidore', 'Tobelo', 'Labuha'],
    'Papua': ['Jayapura', 'Merauke', 'Timika', 'Biak', 'Nabire'],
    'Papua Barat': ['Manokwari', 'Sorong', 'Fakfak', 'Kaimana', 'Bintuni'],
  };
  
  List<Map<String, dynamic>> _courts = []; 

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  int _thumbnailIndex = 0;
  String? _venueLat;
  String? _venueLng;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.venueToEdit?['name'] ?? '');
    _provinsiController = TextEditingController(text: widget.venueToEdit?['provinsi'] ?? '');
    _kotaController = TextEditingController(text: widget.venueToEdit?['location'] ?? '');
    _jalanController = TextEditingController(text: widget.venueToEdit?['address'] ?? '');
    _dllController = TextEditingController(text: widget.venueToEdit?['dll'] ?? '');
    _selectedProvinsi = widget.venueToEdit?['provinsi'];
    _selectedKota = widget.venueToEdit?['location'];

    // Load existing images when editing
    if (widget.venueToEdit != null) {
      _venueLat = widget.venueToEdit!['lat']?.toString();
      _venueLng = widget.venueToEdit!['lng']?.toString();

      final existingImages = widget.venueToEdit!['images'] as List<dynamic>?
          ?? widget.venueToEdit!['imagePaths'] as List<dynamic>?
          ?? [];
      _selectedImages = existingImages
          .map((p) => XFile(p.toString()))
          .toList();
      if (_selectedImages.isNotEmpty) _thumbnailIndex = 0;
    }

    if (widget.venueToEdit != null && widget.venueToEdit!['courts'] != null) {
        _courts = List<Map<String, dynamic>>.from(
        (widget.venueToEdit!['courts'] as List).map((c) {
          final map = Map<String, dynamic>.from(c);
          map['isExpanded'] = false;
          map['activeDayIndex'] = 0;
          _normalizeCourt(map);

          if (map['availability'] == null) {
            map['availability'] = {
              for (var day in _daysOfWeek) day: <String>{'06:00', '07:00', '08:00'}
            };
          } else {
            final rawAvailability = map['availability'] as Map;
            map['availability'] = rawAvailability.map((k, v) => MapEntry(k.toString(), Set<String>.from(v)));
          }

          if (map['priceDay'] == null) {
            map['priceDay'] = { for (var day in _daysOfWeek) day: '' };
          } else {
            map['priceDay'] = Map<String, String>.from(map['priceDay']);
          }

          if (map['services'] == null) {
            map['services'] = <Map<String, dynamic>>[];
          } else {
            map['services'] = List<Map<String, dynamic>>.from(map['services']);
          }

          return map;
        })
      );
    } else {
      _addNewCourt();
    }
  }

  // Pastikan 'facilities' (List) ada di setiap court yang di-load dari edit
  void _normalizeCourt(Map<String, dynamic> map) {
    if (map['facilities'] == null) {
      // Backward compat: lama pakai 'facility' (String)
      final oldFacility = map['facility'] as String?;
      map['facilities'] = oldFacility != null && oldFacility.isNotEmpty ? [oldFacility] : <String>[];
    } else if (map['facilities'] is List) {
      map['facilities'] = List<String>.from(map['facilities']);
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 10) {
      AlertUtils.showToast(context, 'Maksimal 10 foto diperbolehkan.');
      return;
    }
    
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 10) {
          _selectedImages = _selectedImages.sublist(0, 10);
          AlertUtils.showToast(context, 'Hanya 10 foto pertama yang ditambahkan.');
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= 10) {
      AlertUtils.showToast(context, 'Maksimal 10 foto diperbolehkan.');
      return;
    }

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImages.add(photo);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_thumbnailIndex >= _selectedImages.length) {
        _thumbnailIndex = 0;
      }
    });
  }

  void _setThumbnail(int index) {
    setState(() {
      _thumbnailIndex = index;
    });
  }

  void _addNewCourt() {
    setState(() {
      _courts.add({
        'name': 'Lapangan ${_courts.length + 1}',
        'size': '',
        'type': 'Futsal',
        'courtCategory': 'Indoor',
        'floorType': 'Vinyl',
        'facilities': <String>[],  // multi-select
        'priceDay': { for (var day in _daysOfWeek) day: '' },
        'services': <Map<String, dynamic>>[],
        'activeDayIndex': 0,
        'availability': {
          for (var day in _daysOfWeek) day: <String>{'06:00', '07:00', '08:00'}
        },
        'isExpanded': true,
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _provinsiController.dispose();
    _kotaController.dispose();
    _jalanController.dispose();
    _dllController.dispose();
    super.dispose();
  }

  void _saveVenue() async {
    if (_formKey.currentState!.validate()) {
      // Konfirmasi sebelum kirim ke admin
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.send_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Konfirmasi Submit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Data venue akan dikirimkan ke Admin untuk diverifikasi.\n\nPastikan semua informasi sudah benar sebelum melanjutkan.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cek Lagi'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ya, Kirim'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final newVenue = {
        'name': _nameController.text.trim(),
        'location': _selectedKota ?? _kotaController.text.trim(),
        'address': _jalanController.text.trim(),
        'provinsi': _selectedProvinsi ?? _provinsiController.text.trim(),
        'dll': _dllController.text.trim(),
        'type': _courts.isNotEmpty ? _courts[0]['type'] : 'Umum',
        'price': widget.venueToEdit?['price'] ?? 'Hubungi Pengelola',
        'status': widget.venueToEdit?['status'] ?? 'Aktif',
        'hours': '06:00 - 22:00',
        'courts': _courts.map((c) {
          final dynamic availability = c['availability'];
          return {
            'name': c['name'] ?? 'Lapangan',
            'size': c['size'] ?? '-',
            'type': c['type'] ?? 'Umum',
            'courtCategory': c['courtCategory'] ?? 'Indoor',
            'floorType': c['floorType'] ?? 'Vinyl',
            'facilities': c['facilities'] is List ? List<String>.from(c['facilities']) : (c['facility'] != null ? [c['facility']] : <String>[]),
            'priceDay': c['priceDay'],
            'services': c['services'],
            'availability': (availability as Map).map((day, times) {
              if (times is Set) return MapEntry(day, times.toList());
              return MapEntry(day, times);
            }),
          };
                }).toList(),
        'images': _selectedImages.map((e) => e.path).toList(),
        'imagePaths': _selectedImages.map((e) => e.path).toList(),  // alias for admin dialog
        'image': _selectedImages.isNotEmpty ? _selectedImages[_thumbnailIndex].path : '',
        'ownerUsername': GlobalAuthData.currentUser?.username ?? '',
        'lat': double.tryParse(_venueLat ?? '') ?? 0.0,
        'lng': double.tryParse(_venueLng ?? '') ?? 0.0,
      };

      if (widget.venueToEdit != null && widget.index != null) {
        // Edit existing (currently still direct, but could also be a request)
        GlobalVenueData.venues[widget.index!] = newVenue;
        GlobalVenueData.save();
        
        AlertUtils.showResultDialog(
          context,
          isSuccess: true,
          title: 'Berhasil!',
          message: 'Data venue berhasil diperbarui.',
          onConfirm: () => Navigator.pop(context),
        );
      } else {
        // NEW VENUE: Submit for verification
        final user = GlobalAuthData.currentUser;
        // Ambil NIK & NPWP dari data akun owner yang sudah terdaftar
        final ownerVerifReq = GlobalVerificationData.requests
            .where((r) => r.type == 'Owner' && r.username == user?.username)
            .toList();
        final ownerNik  = ownerVerifReq.isNotEmpty ? ownerVerifReq.last.nik  : '-';
        final ownerNpwp = ownerVerifReq.isNotEmpty ? ownerVerifReq.last.npwp : '-';

        final req = VerificationRequest(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          applicantName: user?.applicantName ?? 'Owner',
          email: user?.email ?? '',
          username: user?.username,
          phoneNumber: user?.phoneNumber,
          nik: ownerNik,
          npwp: ownerNpwp,
          documentUrl: '',
          type: 'Venue',
          status: 'Pending',
          submittedAt: DateTime.now(),
          venueName: newVenue['name'],
          venueAddress: newVenue['address'],
          venueProvinsi: newVenue['provinsi'],
          venueKota: newVenue['location'],
          venueLat: _venueLat,
          venueLng: _venueLng,
          venueData: newVenue,
        );

        await GlobalVerificationData.addRequest(req);

        AlertUtils.showResultDialog(
          context,
          isSuccess: true,
          title: 'Berhasil Terkirim!',
          message: 'Venue Anda telah dikirim ke Admin untuk verifikasi. Mohon tunggu persetujuan sebelum venue muncul di publik.',
          onConfirm: () => Navigator.pop(context),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.venueToEdit != null ? 'Edit Venue' : 'Tambah Venue Baru', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageGallerySection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Informasi Utama Venue'),
              _buildCard([
                _buildTextField(_nameController, 'Nama Venue', Icons.stadium),
                const SizedBox(height: 16),
                _buildSearchableDropdown(
                  label: 'Provinsi',
                  icon: Icons.map,
                  value: _selectedProvinsi,
                  items: _provinceCityData.keys.toList(),
                  onSelected: (val) => setState(() {
                    _selectedProvinsi = val;
                    _selectedKota = null; // reset kota
                  }),
                ),
                const SizedBox(height: 16),
                _buildSearchableDropdown(
                  label: 'Kota',
                  icon: Icons.location_city,
                  value: _selectedKota,
                  items: _selectedProvinsi != null
                      ? (_provinceCityData[_selectedProvinsi!] ?? [])
                      : _provinceCityData.values.expand((e) => e).toList(),
                  onSelected: (val) => setState(() => _selectedKota = val),
                  hint: _selectedProvinsi == null ? 'Pilih Provinsi dulu' : 'Pilih Kota',
                ),
                const SizedBox(height: 16),
                _buildTextField(_jalanController, 'Jalan / Alamat Lengkap', Icons.add_location_alt_outlined),
                const SizedBox(height: 16),
                _buildTextField(_dllController, 'Detail Tambahan (Patokan, dll)', Icons.more_horiz),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MapPickerPage()),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        setState(() {
                          _venueLat = result['lat']?.toString();
                          _venueLng = result['lng']?.toString();
                          if (_venueLat != null && _venueLng != null) {
                            _dllController.text = 'Koordinat: $_venueLat, $_venueLng';
                          }
                        });
                      } else if (result != null && result is String) {
                        // backward compat
                        setState(() => _dllController.text = result);
                      }
                    },
                    icon: const Icon(Icons.location_on, color: AppColors.primary),
                    label: const Text('TAMBAHKAN LOKASI DI MAPS', 
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ]),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Daftar Lapangan'),
                  IconButton(
                    onPressed: _addNewCourt,
                    icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 30),
                    tooltip: 'Tambah Lapangan',
                  ),
                ],
              ),
              
              ..._courts.asMap().entries.map((entry) => _buildCourtExpansionTile(entry.key, entry.value)),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveVenue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text('Simpan Data Venue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourtExpansionTile(int index, Map<String, dynamic> court) {
    bool isExpanded = court['isExpanded'] ?? false;
    int activeDayIdx = court['activeDayIndex'] ?? 0;
    String activeDay = _daysOfWeek[activeDayIdx];
    final dynamic availabilityData = court['availability'];
    final Map<String, String> priceDay = court['priceDay'];
    final List<Map<String, dynamic>> services = court['services'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isExpanded ? AppColors.primary : Colors.grey.shade300, width: isExpanded ? 1.5 : 1),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(court['name']?.toString().isEmpty ?? true ? 'Lapangan ${index + 1}' : court['name'], 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: !isExpanded ? Text('${court['type'] ?? 'Umum'} • ${court['courtCategory'] ?? 'Indoor'} • ${court['floorType'] ?? 'Vinyl'}', 
              style: const TextStyle(fontSize: 12)) : null,
            trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onTap: () {
              setState(() {
                _courts[index]['isExpanded'] = !isExpanded;
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildLabelOnlyTextField('Nama Lapangan', (val) => setState(() => _courts[index]['name'] = val), initial: court['name']),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: court['type'],
                    decoration: const InputDecoration(labelText: 'Tipe Olahraga', border: OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always),
                    items: ['Futsal', 'Tenis', 'Badminton', 'Basket', 'Voli'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _courts[index]['type'] = val),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isNarrow = constraints.maxWidth < 400;
                      return isNarrow 
                        ? Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: court['courtCategory'],
                                decoration: const InputDecoration(labelText: 'Tipe Lapangan', border: OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always),
                                items: _courtTypeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) => setState(() => _courts[index]['courtCategory'] = val),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: court['floorType'],
                                decoration: const InputDecoration(labelText: 'Tipe Lantai', border: OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always),
                                items: _floorTypeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) => setState(() => _courts[index]['floorType'] = val),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: court['courtCategory'],
                                  decoration: const InputDecoration(labelText: 'Tipe Lapangan', border: OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always),
                                  items: _courtTypeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (val) => setState(() => _courts[index]['courtCategory'] = val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: court['floorType'],
                                  decoration: const InputDecoration(labelText: 'Tipe Lantai', border: OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always),
                                  items: _floorTypeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (val) => setState(() => _courts[index]['floorType'] = val),
                                ),
                              ),
                            ],
                          );
                    }
                  ),
                  // Ukuran lapangan: 2 kolom P dan L
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('sizeP_$index'),
                          initialValue: (court['size'] ?? '').toString().split('X').firstOrNull?.replaceAll(RegExp(r'[^0-9]'), '').trim(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Panjang (m)',
                            prefixText: 'P  ',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final parts = (court['size'] ?? '').toString().split('X');
                            final l = parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^0-9]'), '').trim() : '';
                            _courts[index]['size'] = 'P $val X L $l';
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('sizeL_$index'),
                          initialValue: (court['size'] ?? '').toString().split('X').length > 1
                              ? (court['size'] ?? '').toString().split('X')[1].replaceAll(RegExp(r'[^0-9]'), '').trim()
                              : '',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Lebar (m)',
                            prefixText: 'L  ',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final parts = (court['size'] ?? '').toString().split('X');
                            final p = parts.isNotEmpty ? parts[0].replaceAll(RegExp(r'[^0-9]'), '').trim() : '';
                            _courts[index]['size'] = 'P $p X L $val';
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Fasilitas multi-select
                  const Text('Fasilitas Lapangan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final List<String> selected = List<String>.from(court['facilities'] ?? []);
                    return Wrap(
                      spacing: 8, runSpacing: 6,
                      children: _facilitiesOptions.map((f) {
                        final isSelected = selected.contains(f);
                        return FilterChip(
                          label: Text(f, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          showCheckmark: true,
                          onSelected: (val) => setState(() {
                            final List<String> cur = List<String>.from(_courts[index]['facilities'] ?? []);
                            if (val) cur.add(f); else cur.remove(f);
                            _courts[index]['facilities'] = cur;
                          }),
                        );
                      }).toList(),
                    );
                  }),
                  // ── Jadwal & Harga ───────────────────────────────────────
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jadwal & Harga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      // Toggle mode harga
                      ChoiceChip(
                        label: Text(
                          court['priceMode'] == 'perSlot' ? 'Harga Per Jam' : 'Harga Sama Semua',
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: court['priceMode'] == 'perSlot',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: court['priceMode'] == 'perSlot' ? Colors.white : Colors.black87,
                          fontSize: 11,
                        ),
                        showCheckmark: false,
                        onSelected: (val) => setState(() {
                          _courts[index]['priceMode'] = val ? 'perSlot' : 'perDay';
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Pilih Hari
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _daysOfWeek.asMap().entries.map((e) {
                        bool isDaySelected = activeDayIdx == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(e.value, style: TextStyle(color: isDaySelected ? Colors.white : Colors.black87, fontSize: 12)),
                            selected: isDaySelected,
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            onSelected: (bool selected) {
                              if (selected) setState(() => _courts[index]['activeDayIndex'] = e.key);
                            },
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Jika mode harga per hari (sama semua jam)
                  if ((court['priceMode'] ?? 'perDay') == 'perDay') ...
                    [
                      TextFormField(
                        key: ValueKey('price_${index}_$activeDay'),
                        initialValue: priceDay[activeDay] ?? '',
                        onChanged: (val) => setState(() => priceDay[activeDay] = val),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga - $activeDay (Rp/Jam, berlaku semua jam)',
                          prefixText: 'Rp ',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                  // Ketersediaan Jam + Tombol Pilih Semua
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ketersediaan Jam ($activeDay):', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            final dynamic dayData = availabilityData?[activeDay];
                            final allSelected = _timeOptions.every((t) =>
                              dayData is Set ? dayData.contains(t) : (dayData as List?)?.contains(t) == true);
                            if (allSelected) {
                              // Hapus semua
                              if (dayData is Set) dayData.clear();
                              else availabilityData[activeDay] = <String>{};
                            } else {
                              // Pilih semua
                              if (dayData is Set) {
                                dayData.addAll(_timeOptions);
                              } else {
                                availabilityData[activeDay] = Set<String>.from(_timeOptions);
                              }
                            }
                          });
                        },
                        icon: const Icon(Icons.select_all, size: 14),
                        label: Builder(builder: (context) {
                          final dynamic dayData = availabilityData?[activeDay];
                          final allSelected = _timeOptions.every((t) =>
                            dayData is Set ? dayData.contains(t) : (dayData as List?)?.contains(t) == true);
                          return Text(allSelected ? 'Hapus Semua' : 'Pilih Semua', style: const TextStyle(fontSize: 12));
                        }),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (availabilityData != null && availabilityData[activeDay] != null)
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _timeOptions.map((time) {
                        final dynamic dayData = availabilityData[activeDay];
                        final bool isSelected = dayData is Set ? dayData.contains(time) : (dayData as List).contains(time);
                        // pricePerSlot map: key = 'day_time'
                        final Map<String, String> pricePerSlot = (court['pricePerSlot'] as Map<String, String>?) ?? {};
                        final slotKey = '${activeDay}_$time';

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilterChip(
                              label: Text(time, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              checkmarkColor: Colors.white,
                              showCheckmark: false,
                              onSelected: (selected) {
                                setState(() {
                                  if (dayData is Set) {
                                    if (selected) dayData.add(time); else dayData.remove(time);
                                  } else {
                                    final List<String> newList = List<String>.from(dayData);
                                    if (selected) newList.add(time); else newList.remove(time);
                                    availabilityData[activeDay] = newList;
                                  }
                                });
                              },
                            ),
                            // Jika mode per jam, tampilkan input harga kecil di bawah chip
                            if ((court['priceMode'] ?? 'perDay') == 'perSlot' && isSelected)
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  initialValue: pricePerSlot[slotKey] ?? '',
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 10),
                                  decoration: InputDecoration(
                                    hintText: 'Rp',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onChanged: (val) {
                                    if (_courts[index]['pricePerSlot'] == null) {
                                      _courts[index]['pricePerSlot'] = <String, String>{};
                                    }
                                    (_courts[index]['pricePerSlot'] as Map<String, String>)[slotKey] = val;
                                  },
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Layanan Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            services.add({'name': '', 'price': '', 'unit': 'Pasang'});
                            _courts[index]['services'] = services;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      ),
                    ],
                  ),
                  ...services.asMap().entries.map((sEntry) {
                    final sIdx = sEntry.key;
                    final sVal = sEntry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildLabelOnlyTextField('Nama Layanan', (val) => sVal['name'] = val, initial: sVal['name'], isDense: true),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _buildLabelOnlyTextField('Harga', (val) => sVal['price'] = val, initial: sVal['price'].toString(), isDense: true, isNumber: true, prefix: 'Rp'),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => setState(() => services.removeAt(sIdx)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                          ),
                        ],
                      ),
                    );
                                    }).toList(),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _courts.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Hapus Lapangan', style: TextStyle(color: Colors.red)),
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabelOnlyTextField(String label, Function(String) onChanged, {String? initial, bool isNumber = false, String? prefix, bool isDense = false}) {
    return TextFormField(
      initialValue: initial,
      onChanged: onChanged,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        isDense: isDense,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
      ),
    );
  }

    Widget _buildImageGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Foto Venue (Maks. 10)'),
        Container(
          height: 125,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + (_selectedImages.length < 10 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return _buildAddImageButton();
              }
              
              return _buildImageItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text('Ambil dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 30),
            SizedBox(height: 8),
            Text('Tambah Foto', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    bool isThumbnail = _thumbnailIndex == index;
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              io.File(_selectedImages[index].path),
              width: 100,
              height: 125,
              fit: BoxFit.cover,
            ),
          ),
          if (isThumbnail)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 10),
                    SizedBox(width: 2),
                    Text('UTAMA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            left: 4,
            child: GestureDetector(
              onTap: () => _setThumbnail(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isThumbnail ? AppColors.primary.withOpacity(0.9) : Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    isThumbnail ? 'Thumbnail Saat Ini' : 'Jadikan Utama',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSearchableDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String) onSelected,
    String? hint,
  }) {
    return GestureDetector(
      onTap: () async {
        final selected = await showDialog<String>(
          context: context,
          builder: (context) => _SearchableDropdownDialog(
            title: label,
            items: items,
            selected: value,
          ),
        );
        if (selected != null) onSelected(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? hint ?? 'Pilih $label',
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null ? AppColors.textPrimary : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder()
      ),
      validator: (value) => value == null || value.isEmpty ? 'Field ini wajib diisi' : null,
    );
  }
}

/// Dialog pencarian untuk Provinsi / Kota — tampilan ala Shopee
class _SearchableDropdownDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selected;

  const _SearchableDropdownDialog({
    required this.title,
    required this.items,
    this.selected,
  });

  @override
  State<_SearchableDropdownDialog> createState() => _SearchableDropdownDialogState();
}

class _SearchableDropdownDialogState extends State<_SearchableDropdownDialog> {
  late List<String> _filtered;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.items);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = widget.items.where((e) => e.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Text(
                  'Pilih ${widget.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari ${widget.title}...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => _searchCtrl.clear())
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const Divider(height: 1),
          // List
          Flexible(
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Tidak ditemukan', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    itemBuilder: (context, idx) {
                      final item = _filtered[idx];
                      final isSelected = item == widget.selected;
                      return ListTile(
                        title: Text(item, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                        tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
                        onTap: () => Navigator.pop(context, item),
                        dense: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
