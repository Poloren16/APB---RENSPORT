import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verification_model.dart';

class GlobalVerificationData {
  static const String _storageKey = 'rensius_verifications';
  static List<VerificationRequest> requests = [];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? requestsJson = prefs.getString(_storageKey);

    if (requestsJson != null) {
      final List<dynamic> decoded = jsonDecode(requestsJson);
      requests = decoded.map((item) => VerificationRequest.fromMap(item)).toList();
    } else {
      requests = [];
    }
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(requests.map((r) => r.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<void> addRequest(VerificationRequest request) async {
    requests.insert(0, request); // Add to top of list
    await save();
  }

  static Future<void> updateRequestStatus(String id, String newStatus, {String? reason}) async {
    final index = requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      requests[index] = requests[index].copyWith(
        status: newStatus,
        rejectionReason: reason,
      );
      await save();
    }
  }
}
