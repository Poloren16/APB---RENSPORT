import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rensius/services/supabase_service.dart';

class GlobalVenueData {
  static const String _storageKey = 'rensius_venues';
  static List<Map<String, dynamic>> favorites = [];
  static List<Map<String, dynamic>> cart = [];
  static List<Map<String, dynamic>> venues = [];

  /// Returns venues owned by a specific owner username.
  /// If ownerUsername is null or empty, returns all venues.
  static List<Map<String, dynamic>> getVenuesForOwner(String? ownerUsername) {
    if (ownerUsername == null || ownerUsername.isEmpty) return venues;
    return venues
        .where((v) => v['ownerUsername'] == ownerUsername)
        .toList();
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? venuesJson = prefs.getString(_storageKey);

    // 1. Muat dari cache lokal agar cepat
    if (venuesJson != null) {
      final List<dynamic> decoded = jsonDecode(venuesJson);
      venues = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      venues = [];
    }

    // 2. Sinkronisasikan secara online dari Supabase
    if (SupabaseService.isInitialized) {
      try {
        final response = await SupabaseService.client.from('venues').select();
        final List<Map<String, dynamic>> onlineVenues = [];
        
        for (var row in response) {
          onlineVenues.add({
            'name': row['name'] ?? '',
            'location': row['location'] ?? '',
            'address': row['address'] ?? '',
            'provinsi': row['provinsi'] ?? '',
            'dll': row['dll'] ?? '',
            'type': row['type'] ?? '',
            'price': row['price'] ?? '',
            'status': row['status'] ?? 'Aktif',
            'hours': row['hours'] ?? '06:00 - 22:00',
            'courts': row['courts'] as List<dynamic>? ?? [],
            'images': row['images'] as List<dynamic>? ?? [],
            'imagePaths': row['image_paths'] as List<dynamic>? ?? [],
            'image': row['image'] ?? '',
            'ownerUsername': row['owner_username'] ?? '',
            'lat': (row['lat'] as num?)?.toDouble() ?? 0.0,
            'lng': (row['lng'] as num?)?.toDouble() ?? 0.0,
          });
        }

        // Gabungkan data online ke local cache
        for (var onlineV in onlineVenues) {
          final idx = venues.indexWhere((v) => v['name'] == onlineV['name']);
          if (idx != -1) {
            venues[idx] = onlineV;
          } else {
            venues.add(onlineV);
          }
        }
        await save();
      } catch (e) {
        print('Gagal sinkronisasi online venue: $e');
      }
    }
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(venues);
    await prefs.setString(_storageKey, encoded);
  }

  static Future<void> addVenue(Map<String, dynamic> venue) async {
    venues.add(venue);
    await save();

    // Simpan online ke Supabase
    if (SupabaseService.isInitialized) {
      try {
        final data = {
          'name': venue['name'],
          'location': venue['location'],
          'address': venue['address'],
          'provinsi': venue['provinsi'],
          'dll': venue['dll'],
          'type': venue['type'],
          'price': venue['price'],
          'status': venue['status'],
          'hours': venue['hours'],
          'courts': venue['courts'],
          'images': venue['images'],
          'image_paths': venue['imagePaths'],
          'image': venue['image'],
          'owner_username': venue['ownerUsername'],
          'lat': venue['lat'],
          'lng': venue['lng'],
        };
        await SupabaseService.client.from('venues').insert(data);
      } catch (e) {
        print('Gagal mengunggah data venue online: $e');
      }
    }
  }

  static void addToCart(Map<String, dynamic> item) {
    cart.add(item);
  }

  static void toggleFavorite(Map<String, dynamic> venue) {
    final exists = favorites.any((v) => v['name'] == venue['name']);
    if (exists) {
      favorites.removeWhere((v) => v['name'] == venue['name']);
    } else {
      favorites.add(venue);
    }
  }

  static bool isFavorite(String venueName) {
    return favorites.any((v) => v['name'] == venueName);
  }
}
