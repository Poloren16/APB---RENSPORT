import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verification_model.dart';
import 'package:rensius/services/supabase_service.dart';
import 'package:rensius/services/supabase_auth_service.dart';

class UserAccount {
  final String username;
  final String password;
  final String role; // 'Admin', 'Owner', 'End User'
  final String applicantName;
  final String email;
  final String phoneNumber;
  
  // New profile fields
  final String bio;
  final List<String> sportsInterests;
  final String instagram;
  final String twitter;
  final String facebook;
  
  // v3 fields
  final String? profileImagePath;
  final String? ktpImagePath; // Separate KTP image path from profile image
  final String gender; // 'Male', 'Female', 'Not Set'
  final String dateOfBirth; // String format 'yyyy-MM-dd'
  final int points;
  final List<Map<String, dynamic>> cart;
  final List<Map<String, dynamic>> favorites;

  UserAccount({
    required this.username,
    required this.password,
    required this.role,
    required this.applicantName,
    this.email = '',
    this.phoneNumber = '',
    this.bio = '',
    this.sportsInterests = const [],
    this.instagram = '',
    this.twitter = '',
    this.facebook = '',
    this.profileImagePath,
    this.ktpImagePath,
    this.gender = 'Not Set',
    this.dateOfBirth = '',
    this.points = 0,
    this.cart = const [],
    this.favorites = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'applicantName': applicantName,
      'email': email,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'sportsInterests': sportsInterests,
      'instagram': instagram,
      'twitter': twitter,
      'facebook': facebook,
      'profileImagePath': profileImagePath,
      'ktpImagePath': ktpImagePath,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'points': points,
      'cart': cart,
      'favorites': favorites,
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      username: map['username'],
      password: map['password'],
      role: map['role'],
      applicantName: map['applicantName'],
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      bio: map['bio'] ?? '',
      sportsInterests: List<String>.from(map['sportsInterests'] ?? []),
      instagram: map['instagram'] ?? '',
      twitter: map['twitter'] ?? '',
      facebook: map['facebook'] ?? '',
      profileImagePath: map['profileImagePath'],
      ktpImagePath: map['ktpImagePath'],
      gender: map['gender'] ?? 'Not Set',
      dateOfBirth: map['dateOfBirth'] ?? '',
      points: map['points'] ?? 0,
      cart: List<Map<String, dynamic>>.from(
          (map['cart'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []),
      favorites: List<Map<String, dynamic>>.from(
          (map['favorites'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []),
    );
  }
}

class GlobalAuthData {
  static const String _storageKey = 'rensius_accounts_v4'; // Bumped version for new default accounts
  static List<UserAccount> accounts = [];
  static UserAccount? currentUser;

  // Initial accounts to be used only if storage is empty
  static final List<UserAccount> _defaultAccounts = [
    UserAccount(
      username: 'admin',
      password: 'admin123',
      role: 'Admin',
      applicantName: 'Rensius Admin',
      email: 'admin@rensius.com',
      phoneNumber: '+6200000000000',
    ),
  ];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? accountsJson = prefs.getString(_storageKey);

    // 1. Muat dari cache lokal terlebih dahulu agar cepat
    if (accountsJson == null) {
      accounts = List.from(_defaultAccounts);
      await save();
    } else {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      accounts = decoded.map((item) => UserAccount.fromMap(item)).toList();
      
      for (var defAcc in _defaultAccounts) {
        if (!accounts.any((a) => a.username == defAcc.username)) {
          accounts.add(defAcc);
        }
      }
      await save();
    }

    // 2. Sinkronisasikan secara online dari Supabase jika aktif
    if (SupabaseService.isInitialized) {
      try {
        final response = await SupabaseService.client.from('users').select();
        final List<UserAccount> onlineAccounts = [];
        for (var row in response) {
          onlineAccounts.add(UserAccount(
            username: row['username'] ?? '',
            password: '', // Password aman di auth.users
            role: row['role'] ?? 'End User',
            applicantName: row['applicant_name'] ?? '',
            email: row['email'] ?? '',
            phoneNumber: row['phone_number'] ?? '',
            bio: row['bio'] ?? '',
            sportsInterests: List<String>.from(row['sports_interests'] ?? []),
            instagram: row['instagram'] ?? '',
            twitter: row['twitter'] ?? '',
            facebook: row['facebook'] ?? '',
            profileImagePath: row['profile_image_path'],
            ktpImagePath: row['ktp_image_path'],
            gender: row['gender'] ?? 'Not Set',
            dateOfBirth: row['date_of_birth'] ?? '',
            points: row['points'] ?? 0,
            cart: List<Map<String, dynamic>>.from(
                (row['cart'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []),
            favorites: List<Map<String, dynamic>>.from(
                (row['favorites'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []),
          ));
        }

        // Gabungkan data online ke lokal cache dan hapus akun lokal yang sudah tidak ada online
        final onlineUsernames = onlineAccounts.map((a) => a.username).toSet();
        accounts.removeWhere((a) => a.role != 'Admin' && !onlineUsernames.contains(a.username));

        for (var onlineAcc in onlineAccounts) {
          final idx = accounts.indexWhere((a) => a.username == onlineAcc.username);
          if (idx != -1) {
            // Update cache dengan data online terbaru, pertahankan password lokal jika ada
            final localPass = accounts[idx].password;
            accounts[idx] = UserAccount(
              username: onlineAcc.username,
              password: (onlineAcc.password.isEmpty && localPass.isNotEmpty) ? localPass : onlineAcc.password,
              role: onlineAcc.role,
              applicantName: onlineAcc.applicantName,
              email: onlineAcc.email,
              phoneNumber: onlineAcc.phoneNumber,
              bio: onlineAcc.bio,
              sportsInterests: onlineAcc.sportsInterests,
              instagram: onlineAcc.instagram,
              twitter: onlineAcc.twitter,
              facebook: onlineAcc.facebook,
              profileImagePath: onlineAcc.profileImagePath,
              ktpImagePath: onlineAcc.ktpImagePath,
              gender: onlineAcc.gender,
              dateOfBirth: onlineAcc.dateOfBirth,
              points: onlineAcc.points,
              cart: onlineAcc.cart,
              favorites: onlineAcc.favorites,
            );
          } else {
            // Tambahkan akun online baru yang belum ada di lokal cache
            accounts.add(onlineAcc);
          }
        }
        await save();
      } catch (e) {
        print('Gagal sinkronisasi online akun: $e');
      }
    }
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(accounts.map((a) => a.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<void> registerAccount(UserAccount account) async {
    final exists = accounts.any((a) => a.username == account.username);
    if (!exists) {
      accounts.add(account);
      await save();
    }
  }

  static UserAccount? login(String username, String password) {
    try {
      final user = accounts.firstWhere(
        (a) => a.username == username && (a.password == password || a.password.isEmpty),
      );
      currentUser = user;
      return user;
    } catch (e) {
      return null;
    }
  }

  static UserAccount? getAccount(String username) {
    try {
      return accounts.firstWhere((a) => a.username == username);
    } catch (e) {
      try {
        return accounts.firstWhere((a) => a.applicantName == username);
      } catch (e2) {
        return null;
      }
    }
  }

  static UserAccount? getAccountByEmail(String email) {
    try {
      return accounts.firstWhere((a) => a.email.toLowerCase() == email.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  static UserAccount? getAccountByEmailOrPhone(String input) {
    final search = input.trim().toLowerCase();
    if (search.isEmpty) return null;
    
    if (search.contains('@')) {
      return getAccountByEmail(search);
    }
    
    final sanitizedInput = search.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitizedInput.isEmpty) return null;
    
    try {
      return accounts.firstWhere((a) {
        final accPhone = a.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
        return accPhone.endsWith(sanitizedInput) || sanitizedInput.endsWith(accPhone);
      });
    } catch (e) {
      return null;
    }
  }

  static bool usernameExists(String username) {
    return accounts.any((a) => a.username == username);
  }

  static bool emailExists(String email) {
    return accounts.any((a) => a.email.toLowerCase().trim() == email.toLowerCase().trim());
  }

  static bool phoneExists(String phone) {
    final sanitized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitized.isEmpty) return false;
    return accounts.any((a) {
      final accPhone = a.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      return accPhone == sanitized;
    });
  }

  static Future<void> deleteAccount(String username) async {
    accounts.removeWhere((a) => a.username == username);
    await save();

    // Hapus online dari Supabase
    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.from('users').delete().eq('username', username);
      } catch (e) {
        print('Gagal menghapus profil online: $e');
      }
    }
  }

  static Future<void> updateAccount(
    String username, {
    String? newName,
    String? newPassword,
    String? newEmail,
    String? newPhone,
    String? newBio,
    List<String>? newSports,
    String? newInsta,
    String? newTwitter,
    String? newFacebook,
    String? newProfileImage,
    String? newKtpImage,
    String? newGender,
    String? newDOB,
    int? newPoints,
  }) async {
    final index = accounts.indexWhere((a) => a.username == username);
    if (index != -1) {
      final old = accounts[index];

      // Unggah foto profil ke Supabase Storage secara dinamis jika online & berupa path lokal
      String? finalProfileImageUrl = newProfileImage ?? old.profileImagePath;
      if (newProfileImage != null && 
          newProfileImage.isNotEmpty &&
          SupabaseService.isInitialized && 
          !newProfileImage.startsWith('http')) {
        try {
          final String? uploadedUrl = await SupabaseService.uploadProfileImage(newProfileImage, username);
          if (uploadedUrl != null) {
            finalProfileImageUrl = uploadedUrl;
          } else {
            // Jika gagal upload ke Supabase online, jangan simpan path lokal ke online DB.
            // Gunakan gambar yang lama (atau null/kosong jika tidak ada).
            finalProfileImageUrl = old.profileImagePath;
            print('Gagal mengunggah foto profil: uploadProfileImage mengembalikan null. Silakan periksa apakah storage bucket "profiles" sudah dibuat dan diset ke Public di Supabase Console.');
          }
        } catch (e) {
          print('Gagal mengunggah foto profil ke Supabase Storage: $e');
          finalProfileImageUrl = old.profileImagePath;
        }
      }

      // Unggah foto KTP ke Supabase Storage secara dinamis jika online & berupa path lokal
      String? finalKtpImageUrl = newKtpImage ?? old.ktpImagePath;
      if (newKtpImage != null && 
          newKtpImage.isNotEmpty &&
          SupabaseService.isInitialized && 
          !newKtpImage.startsWith('http')) {
        try {
          final String? uploadedUrl = await SupabaseService.uploadKtp(newKtpImage, username);
          if (uploadedUrl != null) {
            finalKtpImageUrl = uploadedUrl;
          } else {
            finalKtpImageUrl = old.ktpImagePath;
            print('Gagal mengunggah KTP: uploadKtp mengembalikan null. Silakan periksa apakah storage bucket "documents" sudah dibuat dan diset ke Public di Supabase Console.');
          }
        } catch (e) {
          print('Gagal mengunggah KTP ke Supabase Storage: $e');
          finalKtpImageUrl = old.ktpImagePath;
        }
      }

      final updatedAccount = UserAccount(
        username: username,
        password: newPassword ?? old.password,
        role: old.role,
        applicantName: newName ?? old.applicantName,
        email: newEmail ?? old.email,
        phoneNumber: newPhone ?? old.phoneNumber,
        bio: newBio ?? old.bio,
        sportsInterests: newSports ?? old.sportsInterests,
        instagram: newInsta ?? old.instagram,
        twitter: newTwitter ?? old.twitter,
        facebook: newFacebook ?? old.facebook,
        profileImagePath: finalProfileImageUrl,
        ktpImagePath: finalKtpImageUrl,
        gender: newGender ?? old.gender,
        dateOfBirth: newDOB ?? old.dateOfBirth,
        points: newPoints ?? old.points,
        cart: old.cart,
        favorites: old.favorites,
      );

      accounts[index] = updatedAccount;
      if (currentUser?.username == username) {
        currentUser = accounts[index];
      }
      await save();

      // Sinkronisasikan perubahan online ke Supabase
      if (SupabaseService.isInitialized && old.role != 'Admin') {
        try {
          await SupabaseAuthService.saveUserProfile(updatedAccount);
        } catch (e) {
          print('Gagal memperbarui profil online: $e');
        }
      }
    }
  }

  static Future<void> syncWithVerificationData(List<VerificationRequest> requests) async {
    bool hasChanges = false;
    for (int i = 0; i < accounts.length; i++) {
      var acc = accounts[i];
      if (acc.role.toLowerCase() == 'owner' && (acc.email.isEmpty || acc.phoneNumber.isEmpty)) {
        try {
          final req = requests.firstWhere(
            (r) => r.username == acc.username && r.status == 'Approved'
          );
          
          final updatedAccount = UserAccount(
            username: acc.username,
            password: acc.password,
            role: acc.role,
            applicantName: acc.applicantName,
            email: acc.email.isEmpty ? (req.email ?? '') : acc.email,
            phoneNumber: acc.phoneNumber.isEmpty ? (req.phoneNumber ?? '') : acc.phoneNumber,
            bio: acc.bio,
            sportsInterests: acc.sportsInterests,
            instagram: acc.instagram,
            twitter: acc.twitter,
            facebook: acc.facebook,
            profileImagePath: acc.profileImagePath,
            ktpImagePath: acc.ktpImagePath ?? req.documentUrl,
            gender: acc.gender,
            dateOfBirth: acc.dateOfBirth,
            points: acc.points,
            cart: acc.cart,
            favorites: acc.favorites,
          );

          accounts[i] = updatedAccount;
          hasChanges = true;


        } catch (e) {
          // No matching approved request found
        }
      }
    }
    if (hasChanges) {
      await save();
    }
  }
}
