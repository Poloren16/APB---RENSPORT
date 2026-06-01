import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rensius/services/supabase_service.dart';
import 'package:rensius/data/auth_data.dart';
import 'package:rensius/services/supabase_auth_service.dart';

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
          'price': int.tryParse(venue['price']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0,
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

  static Future<void> deleteVenue(String venueName) async {
    venues.removeWhere((v) => v['name'] == venueName);
    await save();

    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.from('venues').delete().eq('name', venueName);
      } catch (e) {
        print('Gagal menghapus data venue online: $e');
      }
    }
  }

  static Future<void> updateVenue(String oldName, Map<String, dynamic> updatedVenue) async {
    final index = venues.indexWhere((v) => v['name'] == oldName);
    if (index != -1) {
      venues[index] = updatedVenue;
    } else {
      venues.add(updatedVenue);
    }
    await save();

    if (SupabaseService.isInitialized) {
      try {
        final data = {
          'name': updatedVenue['name'],
          'location': updatedVenue['location'],
          'address': updatedVenue['address'],
          'provinsi': updatedVenue['provinsi'],
          'dll': updatedVenue['dll'],
          'type': updatedVenue['type'],
          'price': int.tryParse(updatedVenue['price']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0,
          'status': updatedVenue['status'],
          'hours': updatedVenue['hours'],
          'courts': updatedVenue['courts'],
          'images': updatedVenue['images'],
          'image_paths': updatedVenue['imagePaths'],
          'image': updatedVenue['image'],
          'owner_username': updatedVenue['ownerUsername'],
          'lat': updatedVenue['lat'],
          'lng': updatedVenue['lng'],
        };

        if (oldName != updatedVenue['name']) {
          // Jika nama venue berubah (PK), hapus yang lama dan masukkan yang baru
          await SupabaseService.client.from('venues').delete().eq('name', oldName);
          await SupabaseService.client.from('venues').upsert(data);
        } else {
          // Gunakan upsert agar jika baris tidak ada online (misal sehabis drop table), data otomatis terbuat!
          await SupabaseService.client.from('venues').upsert(data);
        }
      } catch (e) {
        print('Gagal memperbarui data venue online: $e');
      }
    }
  }

  static String activeCartUsername = '';
  static const String _cartStorageKeyPrefix = 'rensius_cart_';

  static Future<void> loadCart(String username) async {
    activeCartUsername = username;
    if (username.isEmpty) {
      cart = [];
      return;
    }
    // 1. Muat dari cache lokal terlebih dahulu agar cepat
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartJson = prefs.getString('${_cartStorageKeyPrefix}$username');
      if (cartJson != null) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        cart = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        cart = [];
      }
    } catch (e) {
      print('Gagal memuat keranjang lokal: $e');
      cart = [];
    }

    // 2. Sinkronisasikan secara online dari Supabase jika aktif
    if (SupabaseService.isInitialized) {
      try {
        final response = await SupabaseService.client
            .from('users')
            .select('cart')
            .eq('username', username)
            .maybeSingle();
        
        if (response != null && response['cart'] != null) {
          final List<dynamic> onlineCartRaw = response['cart'] as List<dynamic>;
          final List<Map<String, dynamic>> onlineCart = onlineCartRaw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          
          if (onlineCart.isNotEmpty) {
            cart = onlineCart;
            // Simpan juga ke cache lokal
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('${_cartStorageKeyPrefix}$username', jsonEncode(cart));
          }
        }
      } catch (e) {
        print('Gagal sinkronisasi online keranjang saat muat: $e');
      }
    }
  }

  static Future<void> saveCart() async {
    if (activeCartUsername.isEmpty) return;
    try {
      // 1. Simpan ke cache lokal terlebih dahulu
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(cart);
      await prefs.setString('${_cartStorageKeyPrefix}$activeCartUsername', encoded);

      // 2. Simpan secara online ke Supabase jika aktif
      if (SupabaseService.isInitialized) {
        // Cari akun lokal untuk diupdate
        final idx = GlobalAuthData.accounts.indexWhere((a) => a.username == activeCartUsername);
        if (idx != -1) {
          final old = GlobalAuthData.accounts[idx];
          final updatedAccount = UserAccount(
            username: old.username,
            password: old.password,
            role: old.role,
            applicantName: old.applicantName,
            email: old.email,
            phoneNumber: old.phoneNumber,
            bio: old.bio,
            sportsInterests: old.sportsInterests,
            instagram: old.instagram,
            twitter: old.twitter,
            facebook: old.facebook,
            profileImagePath: old.profileImagePath,
            ktpImagePath: old.ktpImagePath,
            gender: old.gender,
            dateOfBirth: old.dateOfBirth,
            points: old.points,
            cart: cart, // update cart
            favorites: old.favorites,
          );
          GlobalAuthData.accounts[idx] = updatedAccount;
          if (GlobalAuthData.currentUser?.username == activeCartUsername) {
            GlobalAuthData.currentUser = updatedAccount;
          }
          await GlobalAuthData.save();

          // Kirim perubahan profil ke tabel users di Supabase secara background
          try {
            await SupabaseAuthService.saveUserProfile(updatedAccount);
          } catch (e) {
            print('Gagal sinkronisasi online keranjang saat simpan: $e');
          }
        }
      }
    } catch (e) {
      print('Gagal menyimpan keranjang: $e');
    }
  }

  static void addToCart(Map<String, dynamic> item) {
    // Hindari duplikasi: jika ada item dengan nama venue, lapangan, dan tanggal yang sama, ganti dengan yang baru
    cart.removeWhere((element) =>
        element['venueName'] == item['venueName'] &&
        element['courtName'] == item['courtName'] &&
        element['date'] == item['date']);
        
    cart.add(item);
    saveCart(); // Auto simpan keranjang lokal
  }

  static String activeFavoritesUsername = '';
  static const String _favoritesStorageKeyPrefix = 'rensius_favorites_';

  static Future<void> loadFavorites(String username) async {
    activeFavoritesUsername = username;
    if (username.isEmpty) {
      favorites = [];
      return;
    }
    // 1. Muat dari cache lokal terlebih dahulu agar cepat
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favJson = prefs.getString('${_favoritesStorageKeyPrefix}$username');
      if (favJson != null) {
        final List<dynamic> decoded = jsonDecode(favJson);
        favorites = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        favorites = [];
      }
    } catch (e) {
      print('Gagal memuat favorit lokal: $e');
      favorites = [];
    }

    // 2. Sinkronisasikan secara online dari Supabase jika aktif
    if (SupabaseService.isInitialized) {
      try {
        final response = await SupabaseService.client
            .from('users')
            .select('favorites')
            .eq('username', username)
            .maybeSingle();
        
        if (response != null && response['favorites'] != null) {
          final List<dynamic> onlineFavRaw = response['favorites'] as List<dynamic>;
          final List<Map<String, dynamic>> onlineFav = onlineFavRaw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          
          if (onlineFav.isNotEmpty) {
            favorites = onlineFav;
            // Simpan juga ke cache lokal
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('${_favoritesStorageKeyPrefix}$username', jsonEncode(favorites));
          }
        }
      } catch (e) {
        print('Gagal sinkronisasi online favorit saat muat: $e');
      }
    }
  }

  static Future<void> saveFavorites() async {
    if (activeFavoritesUsername.isEmpty) return;
    try {
      // 1. Simpan ke cache lokal terlebih dahulu
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(favorites);
      await prefs.setString('${_favoritesStorageKeyPrefix}$activeFavoritesUsername', encoded);

      // 2. Simpan secara online ke Supabase jika aktif
      if (SupabaseService.isInitialized) {
        final idx = GlobalAuthData.accounts.indexWhere((a) => a.username == activeFavoritesUsername);
        if (idx != -1) {
          final old = GlobalAuthData.accounts[idx];
          final updatedAccount = UserAccount(
            username: old.username,
            password: old.password,
            role: old.role,
            applicantName: old.applicantName,
            email: old.email,
            phoneNumber: old.phoneNumber,
            bio: old.bio,
            sportsInterests: old.sportsInterests,
            instagram: old.instagram,
            twitter: old.twitter,
            facebook: old.facebook,
            profileImagePath: old.profileImagePath,
            ktpImagePath: old.ktpImagePath,
            gender: old.gender,
            dateOfBirth: old.dateOfBirth,
            points: old.points,
            cart: old.cart,
            favorites: favorites, // update favorites
          );
          GlobalAuthData.accounts[idx] = updatedAccount;
          if (GlobalAuthData.currentUser?.username == activeFavoritesUsername) {
            GlobalAuthData.currentUser = updatedAccount;
          }
          await GlobalAuthData.save();

          try {
            await SupabaseAuthService.saveUserProfile(updatedAccount);
          } catch (e) {
            print('Gagal sinkronisasi online favorit saat simpan: $e');
          }
        }
      }
    } catch (e) {
      print('Gagal menyimpan favorit: $e');
    }
  }

  static void toggleFavorite(Map<String, dynamic> venue) {
    final exists = favorites.any((v) => v['name'] == venue['name']);
    if (exists) {
      favorites.removeWhere((v) => v['name'] == venue['name']);
    } else {
      favorites.add(venue);
    }
    saveFavorites(); // Auto simpan online dan lokal
  }

  static bool isFavorite(String venueName) {
    return favorites.any((v) => v['name'] == venueName);
  }
}
