import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verification_model.dart';
import 'package:rensius/services/supabase_service.dart';

class GlobalVerificationData {
  static const String _storageKey = 'rensius_verifications';
  static List<VerificationRequest> requests = [];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? requestsJson = prefs.getString(_storageKey);

    // 1. Muat dari cache lokal terlebih dahulu agar cepat
    if (requestsJson != null) {
      final List<dynamic> decoded = jsonDecode(requestsJson);
      requests = decoded.map((item) => VerificationRequest.fromMap(item)).toList();
    } else {
      requests = [];
    }

    // 2. Sinkronisasikan secara online dari Supabase
    if (SupabaseService.isInitialized) {
      try {
        final response = await SupabaseService.client.from('verifications').select();
        final List<VerificationRequest> onlineRequests = [];

        for (var row in response) {
          onlineRequests.add(VerificationRequest(
            id: row['id'] ?? '',
            applicantName: row['applicant_name'] ?? '',
            email: row['email'] ?? '',
            username: row['username'],
            phoneNumber: row['phone_number'],
            nik: row['nik'] ?? '',
            npwp: row['npwp'] ?? '',
            documentUrl: row['document_url'] ?? '',
            type: row['type'] ?? '',
            status: row['status'] ?? 'Pending',
            submittedAt: row['submitted_at'] != null 
                ? DateTime.parse(row['submitted_at']) 
                : DateTime.now(),
            venueName: row['venue_name'],
            venueAddress: row['venue_address'],
            venueProvinsi: row['venue_provinsi'],
            venueKota: row['venue_kota'],
            venueLat: row['venue_lat'],
            venueLng: row['venue_lng'],
            venueData: row['venue_data'] != null ? Map<String, dynamic>.from(row['venue_data']) : null,
            rejectionReason: row['rejection_reason'],
            password: row['password'],
          ));
        }

        // Gabungkan data online ke local cache
        for (var onlineReq in onlineRequests) {
          final idx = requests.indexWhere((r) => r.id == onlineReq.id);
          if (idx != -1) {
            requests[idx] = onlineReq;
          } else {
            requests.add(onlineReq);
          }
        }

        // Urutkan berdasarkan waktu kirim terbaru di paling atas
        requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        await save();
      } catch (e) {
        print('Gagal sinkronisasi online verifikasi: $e');
      }
    }
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(requests.map((r) => r.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<void> addRequest(VerificationRequest request) async {
    // Unggah dokumen KTP ke Supabase Storage secara dinamis jika online & berupa path lokal
    String finalDocumentUrl = request.documentUrl;
    if (SupabaseService.isInitialized && 
        finalDocumentUrl.isNotEmpty && 
        !finalDocumentUrl.startsWith('http')) {
      try {
        final String? uploadedUrl = await SupabaseService.uploadKtp(
          finalDocumentUrl, 
          request.username ?? 'anonymous'
        );
        if (uploadedUrl != null) {
          finalDocumentUrl = uploadedUrl;
        } else {
          print('Gagal mengunggah dokumen KTP: uploadKtp mengembalikan null. Silakan periksa storage bucket "documents" di Supabase Console.');
        }
      } catch (e) {
        print('Gagal mengunggah dokumen KTP ke Supabase Storage: $e');
      }
    }

    final updatedRequest = request.copyWith(documentUrl: finalDocumentUrl);

    requests.insert(0, updatedRequest); // Add to top of list
    await save();

    // Simpan online ke Supabase
    if (SupabaseService.isInitialized) {
      try {
        final data = {
          'id': updatedRequest.id,
          'applicant_name': updatedRequest.applicantName,
          'email': updatedRequest.email,
          'username': updatedRequest.username,
          'phone_number': updatedRequest.phoneNumber,
          'nik': updatedRequest.nik,
          'npwp': updatedRequest.npwp,
          'document_url': updatedRequest.documentUrl,
          'type': updatedRequest.type,
          'status': updatedRequest.status,
          'submitted_at': updatedRequest.submittedAt.toIso8601String(),
          'venue_name': updatedRequest.venueName,
          'venue_address': updatedRequest.venueAddress,
          'venue_provinsi': updatedRequest.venueProvinsi,
          'venue_kota': updatedRequest.venueKota,
          'venue_lat': updatedRequest.venueLat,
          'venue_lng': updatedRequest.venueLng,
          'venue_data': updatedRequest.venueData,
          'rejection_reason': updatedRequest.rejectionReason,
          'password': updatedRequest.password,
        };
        await SupabaseService.client.from('verifications').insert(data);
      } catch (e) {
        print('Gagal mengirim verifikasi online: $e');
      }
    }
  }

  static Future<void> updateRequestStatus(String id, String newStatus, {String? reason}) async {
    final index = requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      requests[index] = requests[index].copyWith(
        status: newStatus,
        rejectionReason: reason,
      );
      await save();

      // Perbarui status online di Supabase
      if (SupabaseService.isInitialized) {
        try {
          await SupabaseService.client.from('verifications').update({
            'status': newStatus,
            'rejection_reason': reason,
          }).eq('id', id);
        } catch (e) {
          print('Gagal memperbarui status verifikasi online: $e');
        }
      }
    }
  }
}
