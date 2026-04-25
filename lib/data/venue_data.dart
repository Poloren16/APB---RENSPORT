import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

    if (venuesJson != null) {
      final List<dynamic> decoded = jsonDecode(venuesJson);
      venues = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      venues = [];
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
