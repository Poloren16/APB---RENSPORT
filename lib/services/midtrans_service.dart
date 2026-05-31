import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MidtransService {
  static String get _serverKey {
    return dotenv.env['MIDTRANS_SERVER_KEY'] ?? '';
  }

  static String get _authHeader {
    // Basic Auth header requires base64Encode of serverKey + ":"
    final bytes = utf8.encode('$_serverKey:');
    final base64Str = base64Encode(bytes);
    return 'Basic $base64Str';
  }

  /// Meminta snap token dan snap redirect URL dari Midtrans
  static Future<Map<String, dynamic>> createTransaction({
    required String orderId,
    required int grossAmount,
    required String username,
    required String email,
    required String phone,
    String? courtName,
    String? venueName,
  }) async {
    if (_serverKey.isEmpty) {
      throw Exception('MIDTRANS_SERVER_KEY belum diatur di file .env');
    }

    final url = Uri.parse('https://app.sandbox.midtrans.com/snap/v1/transactions');
    
    final body = {
      'transaction_details': {
        'order_id': orderId,
        'gross_amount': grossAmount,
      },
      'credit_card': {
        'secure': true,
      },
      'customer_details': {
        'first_name': username,
        'email': email.isNotEmpty ? email : 'customer@rensius.com',
        'phone': phone.isNotEmpty ? phone : '081234567890',
      },
      'item_details': [
        {
          'id': orderId,
          'price': grossAmount,
          'quantity': 1,
          'name': '${courtName ?? "Lapangan"} - ${venueName ?? "Venue"}',
        }
      ]
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _authHeader,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final bodyDecoded = jsonDecode(response.body);
        final errorMsg = bodyDecoded['error_messages']?.toString() ?? response.body;
        throw Exception('Gagal membuat transaksi: $errorMsg');
      }
    } catch (e) {
      throw Exception('Kesalahan Jaringan Midtrans: $e');
    }
  }

  /// Memverifikasi status transaksi Midtrans
  /// Mengembalikan status transaksi seperti 'settlement', 'capture', 'pending', 'cancel', 'deny', 'expire'
  static Future<String> checkTransactionStatus(String orderId) async {
    if (_serverKey.isEmpty) {
      throw Exception('MIDTRANS_SERVER_KEY belum diatur di file .env');
    }

    final url = Uri.parse('https://api.sandbox.midtrans.com/v2/$orderId/status');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _authHeader,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transaction_status'] ?? 'pending';
      } else {
        throw Exception('Gagal memeriksa status: Status Code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kesalahan Jaringan Midtrans Status: $e');
    }
  }
}
