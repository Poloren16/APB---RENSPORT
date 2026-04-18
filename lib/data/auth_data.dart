import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  final String gender; // 'Male', 'Female', 'Not Set'
  final String dateOfBirth; // String format 'yyyy-MM-dd'
  final int points;

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
    this.gender = 'Not Set',
    this.dateOfBirth = '',
    this.points = 0,
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
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'points': points,
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
      gender: map['gender'] ?? 'Not Set',
      dateOfBirth: map['dateOfBirth'] ?? '',
      points: map['points'] ?? 0,
    );
  }
}

class GlobalAuthData {
  static const String _storageKey = 'rensius_accounts_v4'; // Bumped version for new default accounts
  static List<UserAccount> accounts = [];

  // Initial accounts to be used only if storage is empty
  static final List<UserAccount> _defaultAccounts = [
    UserAccount(
      username: 'admin',
      password: 'admin123',
      role: 'Admin',
      applicantName: 'System Admin',
      email: 'admin@rensius.com',
      phoneNumber: '+6281234567890',
    ),
    UserAccount(
      username: 'user',
      password: 'user123',
      role: 'End User',
      applicantName: 'Muhammad End User',
      email: 'muhammad@rensius.com',
      phoneNumber: '+6287711223344',
      points: 500,
    ),
    UserAccount(
      username: 'owner',
      password: 'owner123',
      role: 'Owner',
      applicantName: 'Budi Venue Owner',
      email: 'budi@rensius.com',
      phoneNumber: '+6281122334455',
    ),
  ];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? accountsJson = prefs.getString(_storageKey);

    // Fallback and Cleanup migration
    if (accountsJson == null) {
      // For development, we'll force the new default accounts by using a new key
      // or we can check if they exist.
      accounts = List.from(_defaultAccounts);
      await save();
    } else {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      accounts = decoded.map((item) => UserAccount.fromMap(item)).toList();
      
      // Ensure dummy accounts exist
      for (var defAcc in _defaultAccounts) {
        if (!accounts.any((a) => a.username == defAcc.username)) {
          accounts.add(defAcc);
        }
      }
      await save();
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
      return accounts.firstWhere(
        (a) => a.username == username && a.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  static UserAccount? getAccount(String username) {
    try {
      return accounts.firstWhere((a) => a.username == username);
    } catch (e) {
      return null;
    }
  }

  static bool usernameExists(String username) {
    return accounts.any((a) => a.username == username);
  }

  static Future<void> deleteAccount(String username) async {
    accounts.removeWhere((a) => a.username == username);
    await save();
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
    String? newGender,
    String? newDOB,
    int? newPoints,
  }) async {
    final index = accounts.indexWhere((a) => a.username == username);
    if (index != -1) {
      final old = accounts[index];
      accounts[index] = UserAccount(
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
        profileImagePath: newProfileImage ?? old.profileImagePath,
        gender: newGender ?? old.gender,
        dateOfBirth: newDOB ?? old.dateOfBirth,
        points: newPoints ?? old.points,
      );
      await save();
    }
  }
}
