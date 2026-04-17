import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/chat_data.dart';
import 'chat_detail_page.dart';

class ChatPage extends StatefulWidget {
  final String username;
  final String role;

  const ChatPage({super.key, required this.username, required this.role});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String _formatTime(DateTime time) {
    if (DateTime.now().difference(time).inDays == 0 && DateTime.now().day == time.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = widget.role == 'Owner' || widget.role == 'Admin';

    // Filter threads. If Owner, show threads that received messages (for simplicity, show all threads)
    // If User, show threads where username == widget.username
    List<ChatThread> displayThreads = isOwner
        ? GlobalChatData.threads.where((t) => t.messages.isNotEmpty).toList()
        : GlobalChatData.threads.where((t) => t.username == widget.username && t.messages.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: displayThreads.isEmpty
          ? const Center(
              child: Text(
                'Belum ada pesan',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.separated(
              itemCount: displayThreads.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final thread = displayThreads[index];
                
                final displayTitle = isOwner ? thread.username : thread.venueName;
                final lastMsg = thread.messages.last;
                final unreadCount = isOwner ? thread.unreadCounts['owner'] ?? 0 : thread.unreadCounts['user'] ?? 0;

                bool isMe = false;
                if (isOwner && lastMsg.sender == 'owner') {
                  isMe = true;
                } else if (!isOwner && lastMsg.sender == widget.username) {
                  isMe = true;
                }
                
                String subtitleText = isMe ? "Anda: ${lastMsg.text}" : lastMsg.text;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      isOwner ? Icons.person : Icons.stadium,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitleText,
                      style: TextStyle(
                        color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                        fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min, // Prevents overflow
                    children: [
                      Text(
                        _formatTime(lastMsg.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0 ? AppColors.primary : Colors.grey,
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailPage(
                          username: thread.username,
                          venueName: thread.venueName,
                          role: widget.role,
                        ),
                      ),
                    );
                    setState(() {}); // Refresh list to update read status/last message
                  },
                );
              },
            ),
    );
  }
}
