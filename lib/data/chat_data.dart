import 'package:flutter/material.dart';

class ChatMessage {
  final String sender; // username or venueName
  final String text;
  final DateTime timestamp;

  ChatMessage({required this.sender, required this.text, required this.timestamp});
}

class ChatThread {
  final String username;
  final String venueName;
  final List<ChatMessage> messages;
  final Map<String, int> unreadCounts; // 'user' or 'owner'

  ChatThread({
    required this.username,
    required this.venueName,
    required this.messages,
    required this.unreadCounts,
  });
}

class GlobalChatData {
  static List<ChatThread> threads = [
    ChatThread(
      username: 'user',
      venueName: 'Bandung Elektrik Cigereleng Tennis Court',
      unreadCounts: {'user': 0, 'owner': 1},
      messages: [
        ChatMessage(
          sender: 'user',
          text: 'Halo, apakah lapangan A tersedia untuk besok sore?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ],
    ),
  ];

  static ChatThread getThread(String username, String venueName) {
    try {
      return threads.firstWhere(
        (t) => t.username == username && t.venueName == venueName,
      );
    } catch (e) {
      final newThread = ChatThread(
        username: username,
        venueName: venueName,
        messages: [],
        unreadCounts: {'user': 0, 'owner': 0},
      );
      threads.insert(0, newThread);
      return newThread;
    }
  }

  static void addMessage(String username, String venueName, String sender, String text, {bool isOwner = false}) {
    final thread = getThread(username, venueName);
    thread.messages.add(
      ChatMessage(
        sender: sender,
        text: text,
        timestamp: DateTime.now(),
      ),
    );
    
    // Increment unread count for the other party
    if (isOwner) {
      thread.unreadCounts['user'] = (thread.unreadCounts['user'] ?? 0) + 1;
    } else {
      thread.unreadCounts['owner'] = (thread.unreadCounts['owner'] ?? 0) + 1;
    }
  }

  static void markRead(String username, String venueName, {bool isOwner = false}) {
    final thread = getThread(username, venueName);
    if (isOwner) {
      thread.unreadCounts['owner'] = 0;
    } else {
      thread.unreadCounts['user'] = 0;
    }
  }
}
