import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../data/venue_data.dart';
import '../../data/auth_data.dart';
import '../../data/verification_data.dart';
import '../../models/verification_model.dart';
import '../../utils/alert_utils.dart';
import '../../services/supabase_service.dart';
import 'map_picker_page.dart';

class AddVenuePage extends StatefulWidget {
  final Map<String, dynamic>? venueToEdit;
  final int? index;
  final String? ownerUsername;

  const AddVenuePage({super.key, this.venueToEdit, this.index, this.ownerUsername});

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
              for (var day in _daysOfWeek) day: <String>{}
            };
          } else {
            final rawAvailability = map['availability'] as Map;
            map['availability'] = rawAvailability.map((k, v) => MapEntry(k.toString(), Set<String>.from(v)));
          }

          if (map['priceDay'] == null) {
            map['priceDay'] = { for (var day in _daysOfWeek) day: '' };
          } else {
            map['priceDay'] = (map['priceDay'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
          }

          if (map['services'] == null) {
            map['services'] = <Map<String, dynamic>>[];
          } else {
            map['services'] = List<Map<String, dynamic>>.from(map['services']);
          }

          if (map['pricePerSlot'] == null) {
            map['pricePerSlot'] = <String, String>{};
          } else {
            map['pricePerSlot'] = (map['pricePerSlot'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
          }

          if (map['priceMode'] == null) {
            map['priceMode'] = (map['pricePerSlot'] != null && (map['pricePerSlot'] as Map).isNotEmpty) ? 'perSlot' : 'perDay';
          } else {
            map['priceMode'] = map['priceMode'].toString();
          }

          if (map['priceModeDay'] == null) {
            map['priceModeDay'] = <String, String>{};
          } else {
            map['priceModeDay'] = (map['priceModeDay'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
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
    map['image'] = map['image'] ?? '';
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

  void _showPhotoSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Tambah Foto Venue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Ambil dari Kamera langsung'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Pilih dari Galeri foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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
        'image': '',
        'facilities': <String>[],  // multi-select
        'priceDay': { for (var day in _daysOfWeek) day: '' },
        'services': <Map<String, dynamic>>[],
        'activeDayIndex': 0,
        'availability': {
          for (var day in _daysOfWeek) day: <String>{}
        },
        'priceMode': 'perDay',
        'priceModeDay': <String, String>{},
        'pricePerSlot': <String, String>{},
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
    // Validasi harga slot/harian dari semua court untuk hari-hari yang aktif
    for (int i = 0; i < _courts.length; i++) {
      final court = _courts[i];
      final courtName = court['name'] ?? 'Lapangan ${i + 1}';
      final priceDay = court['priceDay'] as Map? ?? {};
      final priceModeDay = court['priceModeDay'] as Map? ?? {};
      final pricePerSlot = court['pricePerSlot'] as Map? ?? {};
      final availability = court['availability'] as Map? ?? {};

      for (final dayName in _daysOfWeek) {
        final dynamic times = availability[dayName];
        final bool hasSlots = times != null && (times is Set ? times.isNotEmpty : (times as List).isNotEmpty);
        
        if (hasSlots) {
          final dayPriceMode = priceModeDay[dayName] ?? court['priceMode'] ?? 'perDay';
          if (dayPriceMode == 'perDay') {
            final val = priceDay[dayName]?.toString().trim() ?? '';
            if (val.isEmpty) {
              AlertUtils.showToast(context, 'Harga harian $courtName pada hari $dayName wajib diisi.');
              return;
            }
            final p = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
            if (p == null || p <= 0) {
              AlertUtils.showToast(context, 'Harga harian $courtName pada hari $dayName tidak boleh 0.');
              return;
            }
          } else {
            // perSlot
            final List<String> slotTimes = List<String>.from(times as Iterable);
            for (final time in slotTimes) {
              final slotKey = '${dayName}_$time';
              final val = pricePerSlot[slotKey]?.toString().trim() ?? '';
              if (val.isEmpty) {
                AlertUtils.showToast(context, 'Harga slot $time $courtName pada hari $dayName wajib diisi.');
                return;
              }
              final p = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
              if (p == null || p <= 0) {
                AlertUtils.showToast(context, 'Harga slot $time $courtName pada hari $dayName tidak boleh 0.');
                return;
              }
            }
          }
        }
      }
    }

    if (_formKey.currentState!.validate()) {
      // Konfirmasi sebelum kirim/simpan
      final isEdit = widget.venueToEdit != null;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.save_rounded : Icons.send_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(isEdit ? 'Konfirmasi Simpan' : 'Konfirmasi Submit', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            isEdit 
                ? 'Apakah Anda yakin ingin menyimpan seluruh perubahan data venue ini?'
                : 'Data venue akan dikirimkan ke Admin untuk diverifikasi.\n\nPastikan semua informasi sudah benar sebelum melanjutkan.',
            style: const TextStyle(fontSize: 14),
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
              child: Text(isEdit ? 'Ya, Simpan' : 'Ya, Kirim'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      // Show uploading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Mengunggah gambar...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );

      // Upload main venue images
      final List<String> uploadedImages = [];
      String mainImageUrl = '';

      for (int i = 0; i < _selectedImages.length; i++) {
        final path = _selectedImages[i].path;
        if (path.startsWith('http://') || path.startsWith('https://')) {
          uploadedImages.add(path);
          if (i == _thumbnailIndex) {
            mainImageUrl = path;
          }
        } else {
          final extension = path.split('.').last;
          final destination = 'venue_img_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
          final publicUrl = await SupabaseService.uploadFile(
            bucketName: 'venues',
            filePath: path,
            destinationPath: destination,
          );
          if (publicUrl != null) {
            uploadedImages.add(publicUrl);
            if (i == _thumbnailIndex) {
              mainImageUrl = publicUrl;
            }
          } else {
            uploadedImages.add(path); // Fallback to local path if upload fails
          }
        }
      }

      // Upload individual court images
      final List<Map<String, dynamic>> processedCourts = [];
      for (int i = 0; i < _courts.length; i++) {
        final c = _courts[i];
        final courtMap = Map<String, dynamic>.from(c);
        final courtImgPath = courtMap['image']?.toString() ?? '';
        
        if (courtImgPath.isNotEmpty && 
            !courtImgPath.startsWith('http://') && 
            !courtImgPath.startsWith('https://')) {
          final extension = courtImgPath.split('.').last;
          final destination = 'court_img_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
          final publicUrl = await SupabaseService.uploadFile(
            bucketName: 'venues',
            filePath: courtImgPath,
            destinationPath: destination,
          );
          if (publicUrl != null) {
            courtMap['image'] = publicUrl;
          }
        }
        processedCourts.add(courtMap);
      }

      if (mounted) {
        Navigator.pop(context); // Dismiss the uploading loading dialog!
      }

      int lowestPrice = 99999999;
      for (final c in processedCourts) {
        // Cek priceDay
        final priceDay = c['priceDay'] as Map? ?? {};
        for (final val in priceDay.values) {
          final cleanVal = val?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
          if (cleanVal.isNotEmpty) {
            final p = int.tryParse(cleanVal);
            if (p != null && p > 0 && p < lowestPrice) lowestPrice = p;
          }
        }
        // Cek pricePerSlot
        final pricePerSlot = c['pricePerSlot'] as Map? ?? {};
        for (final val in pricePerSlot.values) {
          final cleanVal = val?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
          if (cleanVal.isNotEmpty) {
            final p = int.tryParse(cleanVal);
            if (p != null && p > 0 && p < lowestPrice) lowestPrice = p;
          }
        }
      }
      final venuePrice = lowestPrice == 99999999 ? 'Hubungi Pengelola' : lowestPrice.toString();

      final newVenue = {
        'name': _nameController.text.trim(),
        'location': _selectedKota ?? _kotaController.text.trim(),
        'address': _jalanController.text.trim(),
        'provinsi': _selectedProvinsi ?? _provinsiController.text.trim(),
        'dll': _dllController.text.trim(),
        'type': processedCourts.isNotEmpty ? processedCourts[0]['type'] : 'Umum',
        'price': venuePrice,
        'status': widget.venueToEdit?['status'] ?? 'Aktif',
        'hours': '06:00 - 22:00',
        'courts': processedCourts.map((c) {
          final dynamic availability = c['availability'];
          return {
            'name': c['name'] ?? 'Lapangan',
            'size': c['size'] ?? '-',
            'type': c['type'] ?? 'Umum',
            'courtCategory': c['courtCategory'] ?? 'Indoor',
            'floorType': c['floorType'] ?? 'Vinyl',
            'image': c['image'] ?? '',
            'facilities': c['facilities'] is List ? List<String>.from(c['facilities']) : (c['facility'] != null ? [c['facility']] : <String>[]),
            'priceDay': c['priceDay'],
            'priceMode': c['priceMode'] ?? 'perDay',
            'priceModeDay': c['priceModeDay'] ?? <String, String>{},
            'pricePerSlot': c['pricePerSlot'] ?? <String, String>{},
            'services': c['services'],
            'availability': (availability as Map).map((day, times) {
              if (times is Set) return MapEntry(day, times.toList());
              return MapEntry(day, times);
            }),
          };
        }).toList(),
        'images': uploadedImages,
        'imagePaths': uploadedImages,
        'image': mainImageUrl.isNotEmpty ? mainImageUrl : (uploadedImages.isNotEmpty ? uploadedImages.first : ''),
        'ownerUsername': (GlobalAuthData.currentUser ?? GlobalAuthData.getAccount(widget.ownerUsername ?? ''))?.username ?? widget.ownerUsername ?? '',
        'lat': double.tryParse(_venueLat ?? '') ?? 0.0,
        'lng': double.tryParse(_venueLng ?? '') ?? 0.0,
      };

      if (widget.venueToEdit != null && widget.index != null) {
        await GlobalVenueData.updateVenue(widget.venueToEdit!['name'] ?? '', newVenue);

        AlertUtils.showResultDialog(
          context,
          isSuccess: true,
          title: 'Berhasil!',
          message: 'Data venue berhasil diperbarui.',
          onConfirm: () {
            Navigator.pop(context); // Pops the AddVenuePage
          },
        );
      } else {
        // NEW VENUE: Submit for verification
        final user = GlobalAuthData.currentUser ?? GlobalAuthData.getAccount(widget.ownerUsername ?? '');
        // Ambil NIK & NPWP dari data akun owner yang sudah terdaftar
        final ownerVerifReq = GlobalVerificationData.requests
            .where((r) => r.type == 'Owner' && r.username == user?.username)
            .toList();
        final ownerNik  = ownerVerifReq.isNotEmpty ? ownerVerifReq.last.nik  : '-';
        final ownerNpwp = ownerVerifReq.isNotEmpty ? ownerVerifReq.last.npwp : '-';
        final ownerKtp  = (user?.ktpImagePath != null && user!.ktpImagePath!.isNotEmpty)
            ? user.ktpImagePath
            : ((user?.profileImagePath != null && user!.profileImagePath!.isNotEmpty)
                ? user.profileImagePath
                : (ownerVerifReq.isNotEmpty ? ownerVerifReq.last.documentUrl : ''));

        final req = VerificationRequest(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          applicantName: user?.applicantName ?? 'Owner',
          email: user?.email ?? '',
          username: user?.username ?? widget.ownerUsername,
          phoneNumber: user?.phoneNumber,
          nik: ownerNik,
          npwp: ownerNpwp,
          documentUrl: ownerKtp ?? '',
          type: 'Venue',
          status: 'Pending',
          submittedAt: DateTime.now(),
          venueName: newVenue['name'] as String?,
          venueAddress: newVenue['address'] as String?,
          venueProvinsi: newVenue['provinsi'] as String?,
          venueKota: newVenue['location'] as String?,
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
          onConfirm: () {
            Navigator.pop(context); // Pops the AddVenuePage
          },
        );
      }
    }
  }

  Future<bool?> _showDiscardChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Text('Keluar Halaman?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Seluruh perubahan yang belum disimpan akan hilang. Apakah Anda yakin ingin keluar?',
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
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showCourtPhotoSourceBottomSheet(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Tambah Foto Lapangan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Ambil dari Kamera langsung'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _courts[index]['image'] = image.path;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Pilih dari Galeri foto'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _courts[index]['image'] = image.path;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () async {
            final confirm = await _showDiscardChangesDialog();
            if (confirm == true && mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final confirm = await _showDiscardChangesDialog();
          if (confirm == true && mounted) {
            Navigator.pop(context);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              _buildSectionTitle('Foto Venue (Maksimal 10)'),
              _buildCard([
                if (_selectedImages.isEmpty)
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: InkWell(
                      onTap: _showPhotoSourceBottomSheet,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Belum ada foto terpilih', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Ketuk untuk menambah dari Kamera / Galeri (Maks 10)', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            final file = _selectedImages[index];
                            final isMain = index == _thumbnailIndex;
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 120,
                              height: 120,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: file.path.startsWith('http://') || file.path.startsWith('https://')
                                        ? Image.network(
                                            file.path,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 120,
                                              height: 120,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          )
                                        : Image.file(
                                            File(file.path),
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 120,
                                              height: 120,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          ),
                                  ),
                                  // Badge for Main/Utama Photo
                                  if (isMain)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.star, color: Colors.white, size: 10),
                                            SizedBox(width: 2),
                                            Text('Utama', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  // Remove Button
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.black.withOpacity(0.6),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.close, color: Colors.white, size: 14),
                                        onPressed: () => _removeImage(index),
                                      ),
                                    ),
                                  ),
                                  // Set Main Overlay
                                  if (!isMain)
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () => _setThumbnail(index),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Set Utama',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add_photo_alternate, size: 18),
                              label: const Text('Galeri', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _takePhoto,
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Kamera', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
              const SizedBox(height: 320),
            ],
          ),
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
    final dayPriceMode = (court['priceModeDay'] as Map? ?? {})[activeDay] ?? court['priceMode'] ?? 'perDay';
    
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
                  // Foto Lapangan (Opsional)
                  const Text('Foto Lapangan (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showCourtPhotoSourceBottomSheet(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: court['image'] != null && court['image'].toString().isNotEmpty
                              ? (court['image'].toString().startsWith('http://') || court['image'].toString().startsWith('https://')
                                  ? Image.network(court['image'].toString(), width: 80, height: 80, fit: BoxFit.cover)
                                  : Image.file(File(court['image'].toString()), width: 80, height: 80, fit: BoxFit.cover))
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 28),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCourtPhotoSourceBottomSheet(index),
                        icon: const Icon(Icons.photo_library, size: 16, color: Colors.white),
                        label: const Text('Pilih Foto', style: TextStyle(fontSize: 12, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      if (court['image'] != null && court['image'].toString().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _courts[index]['image'] = '';
                            });
                          },
                          child: const Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: court['type'],
                    decoration: const InputDecoration(labelText: 'Tipe Olahraga', border: OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always),
                    items: ['Futsal', 'Mini Soccer', 'Sepak Bola', 'Badminton', 'Tennis', 'Basket', 'Voli'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
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
                  const SizedBox(height: 16),
                  // Ukuran lapangan: 2 kolom P dan L
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('sizeP_$index'),
                          initialValue: (court['size'] ?? '').toString().split('X').firstOrNull?.replaceAll(RegExp(r'[^0-9]'), '').trim(),
                          keyboardType: TextInputType.number,
                          scrollPadding: const EdgeInsets.only(bottom: 200),
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
                          scrollPadding: const EdgeInsets.only(bottom: 200),
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
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text('Jadwal & Harga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        // Toggle mode harga
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChoiceChip(
                              label: const Text('Flat Harian', style: TextStyle(fontSize: 11)),
                              selected: ((court['priceModeDay'] as Map? ?? {})[activeDay] ?? court['priceMode'] ?? 'perDay') == 'perDay',
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: ((court['priceModeDay'] as Map? ?? {})[activeDay] ?? court['priceMode'] ?? 'perDay') == 'perDay' ? Colors.white : Colors.black87,
                                fontSize: 11,
                              ),
                              showCheckmark: false,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    if (_courts[index]['priceModeDay'] == null) {
                                      _courts[index]['priceModeDay'] = <String, String>{};
                                    }
                                    (_courts[index]['priceModeDay'] as Map)[activeDay] = 'perDay';
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Beda Per Jam', style: TextStyle(fontSize: 11)),
                              selected: ((court['priceModeDay'] as Map? ?? {})[activeDay] ?? court['priceMode'] ?? 'perDay') == 'perSlot',
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: ((court['priceModeDay'] as Map? ?? {})[activeDay] ?? court['priceMode'] ?? 'perDay') == 'perSlot' ? Colors.white : Colors.black87,
                                fontSize: 11,
                              ),
                              showCheckmark: false,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    if (_courts[index]['priceModeDay'] == null) {
                                      _courts[index]['priceModeDay'] = <String, String>{};
                                    }
                                    (_courts[index]['priceModeDay'] as Map)[activeDay] = 'perSlot';
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
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
                  if (dayPriceMode == 'perDay') ...
                    [
                      TextFormField(
                        key: ValueKey('price_${index}_$activeDay'),
                        initialValue: priceDay[activeDay] ?? '',
                        onChanged: (val) => setState(() => priceDay[activeDay] = val),
                        keyboardType: TextInputType.number,
                        scrollPadding: const EdgeInsets.only(bottom: 200),
                        decoration: InputDecoration(
                          labelText: 'Harga - $activeDay (Rp/Jam, berlaku semua jam)',
                          prefixText: 'Rp ',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Harga harian wajib diisi';
                          }
                          final p = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                          if (p == null || p <= 0) {
                            return 'Harga harus lebih besar dari 0';
                          }
                          return null;
                        },
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
                        final Map<String, String> pricePerSlot = court['pricePerSlot'] != null 
                             ? (court['pricePerSlot'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
                             : <String, String>{};
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
                            if (dayPriceMode == 'perSlot' && isSelected)
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  key: ValueKey('priceSlot_${index}_${slotKey}'),
                                  initialValue: pricePerSlot[slotKey] ?? '',
                                  keyboardType: TextInputType.number,
                                  scrollPadding: const EdgeInsets.only(bottom: 200),
                                  style: const TextStyle(fontSize: 10),
                                  decoration: InputDecoration(
                                    hintText: 'Rp',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    errorStyle: const TextStyle(fontSize: 8, height: 1),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Wajib';
                                    }
                                    final p = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                                    if (p == null || p <= 0) {
                                      return 'Min 1';
                                    }
                                    return null;
                                  },
                                  onChanged: (val) {
                                    if (_courts[index]['pricePerSlot'] == null) {
                                      _courts[index]['pricePerSlot'] = <String, String>{};
                                    }
                                    (_courts[index]['pricePerSlot'] as Map)[slotKey] = val;
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
                            services.add({'name': '', 'price': '', 'unit': 'Pasang', 'stock': ''});
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildLabelOnlyTextField(
                                  'Stok (kosong = tidak terbatas)',
                                  (val) => sVal['stock'] = val,
                                  initial: sVal['stock']?.toString() ?? '',
                                  isDense: true,
                                  isNumber: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String> (
                                  value: (sVal['unit']?.toString().isNotEmpty == true) ? sVal['unit'].toString() : 'Pasang',
                                  decoration: const InputDecoration(
                                    labelText: 'Satuan',
                                    border: OutlineInputBorder(),
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: ['Pasang', 'Buah', 'Set', 'Lembar', 'Botol', 'Pcs']
                                      .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
                                      .toList(),
                                  onChanged: (val) => setState(() => sVal['unit'] = val ?? 'Pasang'),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
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
      scrollPadding: const EdgeInsets.only(bottom: 200),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        isDense: isDense,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
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
      scrollPadding: const EdgeInsets.only(bottom: 200),
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
