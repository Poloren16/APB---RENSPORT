import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserAccount {
  final String username;
  final String password;
  final String role; // 'Admin', 'Owner', 'End User'
  final String applicantName;

  UserAccount({
    required this.username,
    required this.password,
    required this.role,
    required this.applicantName,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'applicantName': applicantName,
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      username: map['username'],
      password: map['password'],
      role: map['role'],
      applicantName: map['applicantName'],
    );
  }
}

class GlobalAuthData {
  static const String _storageKey = 'rensius_accounts';
  static List<UserAccount> accounts = [];

  // Initial accounts to be used only if storage is empty
  static final List<UserAccount> _defaultAccounts = [
    UserAccount(
      username: 'admin',
      password: 'admin123321098890',
      role: 'Admin',
      applicantName: 'System Admin',
    ),
    UserAccount(
      username: 'user',
      password: 'user123',
      role: 'End User',
      applicantName: 'Regular User',
    ),
    UserAccount(
      username: 'owner1',
      password: 'password123',
      role: 'Owner',
      applicantName: 'Budi Santoso',
    ),
  ];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString(_storageKey);

    if (accountsJson != null) {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      accounts = decoded.map((item) => UserAccount.fromMap(item)).toList();
    } else {
      // First time app launch, use default accounts
      accounts = List.from(_defaultAccounts);
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

  static bool usernameExists(String username) {
    return accounts.any((a) => a.username == username);
  }

  static Future<void> deleteAccount(String username) async {
    accounts.removeWhere((a) => a.username == username);
    await save();
  }

  static Future<void> updateAccount(String username, String newName, String newPassword) async {
    final index = accounts.indexWhere((a) => a.username == username);
    if (index != -1) {
      accounts[index] = UserAccount(
        username: username,
        password: newPassword,
        role: accounts[index].role,
        applicantName: newName,
      );
      await save();
    }
  }
}
