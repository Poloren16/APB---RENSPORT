import 'package:flutter/material.dart';
import 'package:rensius/services/supabase_service.dart';

class ChatMessage {
  final String id;
  final String sender; // username or 'owner'
  final String text;
  final DateTime timestamp;
  bool readByUser;
  bool readByOwner;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.readByUser = false,
    this.readByOwner = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString() ?? '',
      sender: map['sender']?.toString() ?? '',
      text: map['message']?.toString() ?? '',
      timestamp: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString()).toLocal()
          : DateTime.now(),
      readByUser: map['read_by_user'] == true,
      readByOwner: map['read_by_owner'] == true,
    );
  }
}

class ChatThread {
  final String username;
  final String venueName;
  final List<ChatMessage> messages;

  ChatThread({
    required this.username,
    required this.venueName,
    required this.messages,
  });

  /// Unread count for the given perspective
  int unreadCountFor({required bool isOwner}) {
    return messages.where((m) {
      if (isOwner) return !m.readByOwner;
      return !m.readByUser;
    }).length;
  }
}

class GlobalChatData {
  /// In-memory cache of threads keyed by "username|venueName"
  static final Map<String, ChatThread> _threadMap = {};

  static List<ChatThread> get threads => _threadMap.values.toList()
    ..sort((a, b) {
      final aLast = a.messages.isNotEmpty ? a.messages.last.timestamp : DateTime(2000);
      final bLast = b.messages.isNotEmpty ? b.messages.last.timestamp : DateTime(2000);
      return bLast.compareTo(aLast);
    });

  /// Returns a thread for the given pair, creating empty if not found.
  static ChatThread getThread(String username, String venueName) {
    final key = '$username|$venueName';
    _threadMap.putIfAbsent(
      key,
      () => ChatThread(username: username, venueName: venueName, messages: []),
    );
    return _threadMap[key]!;
  }

  // ===========================================================================
  // SUPABASE ONLINE OPERATIONS
  // ===========================================================================

  /// Memuat semua thread chat dari Supabase ke dalam memory cache.
  /// Panggil ini saat membuka halaman list chat atau chat detail.
  static Future<void> loadThreads({String? filterUsername, String? filterVenueName}) async {
    if (!SupabaseService.isInitialized) return;
    try {
      var query = SupabaseService.client.from('chats').select();

      if (filterUsername != null && filterVenueName != null) {
        query = query
            .eq('username', filterUsername)
            .eq('venue_name', filterVenueName);
      } else if (filterUsername != null) {
        query = query.eq('username', filterUsername);
      }

      final response = await query.order('created_at', ascending: true);

      // Clear existing cache before re-loading
      if (filterUsername == null && filterVenueName == null) {
        _threadMap.clear();
      } else {
        // Hapus pesan sementara (optimistic update) agar tidak kedouble saat memuat ulang dari database
        if (filterUsername != null && filterVenueName != null) {
          final key = '$filterUsername|$filterVenueName';
          if (_threadMap.containsKey(key)) {
            _threadMap[key]!.messages.removeWhere((m) => m.id.startsWith('temp_'));
          }
        } else if (filterUsername != null) {
          final prefix = '$filterUsername|';
          _threadMap.keys.where((k) => k.startsWith(prefix)).forEach((key) {
            _threadMap[key]!.messages.removeWhere((m) => m.id.startsWith('temp_'));
          });
        }
      }

      for (var row in response) {
        final username = row['username']?.toString() ?? '';
        final venueName = row['venue_name']?.toString() ?? '';
        final key = '$username|$venueName';

        _threadMap.putIfAbsent(
          key,
          () => ChatThread(username: username, venueName: venueName, messages: []),
        );

        final msg = ChatMessage.fromMap(row);
        // Avoid duplicates
        final existingIds = _threadMap[key]!.messages.map((m) => m.id).toSet();
        if (!existingIds.contains(msg.id)) {
          _threadMap[key]!.messages.add(msg);
        }
      }
    } catch (e) {
      debugPrint('Gagal memuat thread chat dari Supabase: $e');
    }
  }

  /// Mengirim pesan baru dan menyimpannya ke Supabase.
  static Future<void> sendMessage({
    required String username,
    required String venueName,
    required String sender,
    required String text,
    required bool isOwner,
  }) async {
    final payload = {
      'username': username,
      'venue_name': venueName,
      'sender': sender,
      'message': text,
      'read_by_user': isOwner ? false : true,   // sender sudah baca otomatis
      'read_by_owner': isOwner ? true : false,
    };

    // Optimistic update ke memory dulu agar UI terasa instan
    final key = '$username|$venueName';
    _threadMap.putIfAbsent(
      key,
      () => ChatThread(username: username, venueName: venueName, messages: []),
    );
    final optimisticMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sender: sender,
      text: text,
      timestamp: DateTime.now(),
      readByUser: !isOwner,
      readByOwner: isOwner,
    );
    _threadMap[key]!.messages.add(optimisticMsg);

    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.from('chats').insert(payload);
      } catch (e) {
        debugPrint('Gagal mengirim pesan ke Supabase: $e');
        // Rollback optimistic update jika gagal
        _threadMap[key]!.messages.remove(optimisticMsg);
      }
    }
  }

  /// Menandai semua pesan dalam thread sebagai sudah dibaca sesuai perspektif.
  static Future<void> markReadOnline({
    required String username,
    required String venueName,
    required bool isOwner,
  }) async {
    // Update memory cache
    final key = '$username|$venueName';
    if (_threadMap.containsKey(key)) {
      for (var msg in _threadMap[key]!.messages) {
        if (isOwner) {
          msg.readByOwner = true;
        } else {
          msg.readByUser = true;
        }
      }
    }

    // Update ke Supabase
    if (!SupabaseService.isInitialized) return;
    try {
      final updateField = isOwner ? 'read_by_owner' : 'read_by_user';
      await SupabaseService.client
          .from('chats')
          .update({updateField: true})
          .eq('username', username)
          .eq('venue_name', venueName);
    } catch (e) {
      debugPrint('Gagal menandai chat sebagai sudah dibaca di Supabase: $e');
    }
  }

  /// Hitung total pesan belum dibaca untuk user tertentu.
  static int getTotalUnreadCount(String username, String role) {
    final isOwner = role == 'Owner' || role == 'Admin';
    int total = 0;
    for (var thread in threads) {
      if (isOwner) {
        total += thread.unreadCountFor(isOwner: true);
      } else {
        if (thread.username == username) {
          total += thread.unreadCountFor(isOwner: false);
        }
      }
    }
    return total;
  }

  /// [DEPRECATED — gunakan sendMessage()] Kept for backward compatibility.
  static void addMessage(
    String username,
    String venueName,
    String sender,
    String text, {
    bool isOwner = false,
  }) {
    sendMessage(
      username: username,
      venueName: venueName,
      sender: sender,
      text: text,
      isOwner: isOwner,
    );
  }

  /// [DEPRECATED — gunakan markReadOnline()] Kept for backward compatibility.
  static void markRead(String username, String venueName, {bool isOwner = false}) {
    markReadOnline(username: username, venueName: venueName, isOwner: isOwner);
  }
}
