import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_colors.dart';
import '../data/chat_data.dart';
import 'chat_detail_page.dart';
import '../widgets/empty_state_widget.dart';
import '../data/auth_data.dart';
import '../data/venue_data.dart';

class ChatPage extends StatefulWidget {
  final String username;
  final String role;
  final VoidCallback? onBack;

  const ChatPage({
    super.key,
    required this.username,
    required this.role,
    this.onBack,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    final bool isOwner = widget.role == 'Owner' || widget.role == 'Admin';
    await GlobalChatData.loadThreads(
      filterUsername: isOwner ? null : widget.username,
    );
    if (mounted) setState(() => _isLoading = false);
  }

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
          'Pesan',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayThreads.isEmpty
          ? const EmptyStateWidget(
              message: 'Belum ada pesan',
              subMessage: 'Hubungi pengelola venue untuk menanyakan jadwal atau fasilitas lainnya!',
            )
          : ListView.separated(
              itemCount: displayThreads.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final thread = displayThreads[index];
                
                final displayTitle = isOwner ? thread.username : thread.venueName;
                final lastMsg = thread.messages.last;
                final unreadCount = thread.unreadCountFor(isOwner: isOwner);

                bool isMe = false;
                if (isOwner && lastMsg.sender == 'owner') {
                  isMe = true;
                } else if (!isOwner && lastMsg.sender == widget.username) {
                  isMe = true;
                }
                
                String subtitleText = isMe ? "Anda: ${lastMsg.text}" : lastMsg.text;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Builder(
                    builder: (context) {
                      String? imagePath;
                      IconData fallbackIcon = Icons.person;
                      
                      if (isOwner) {
                        // Lawan bicara adalah user. Ambil profil user.
                        imagePath = GlobalAuthData.getAccount(thread.username)?.profileImagePath;
                        fallbackIcon = Icons.person;
                      } else {
                        // Lawan bicara adalah venue. Ambil gambar venue.
                        final venue = GlobalVenueData.venues.firstWhere(
                          (v) => v['name'] == thread.venueName,
                          orElse: () => <String, dynamic>{},
                        );
                        imagePath = venue['image']?.toString();
                        fallbackIcon = Icons.stadium;
                      }

                      if (imagePath == null || imagePath.isEmpty) {
                        return CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(fallbackIcon, color: AppColors.primary, size: 24),
                        );
                      }

                      final isRemote = imagePath.startsWith('http://') || imagePath.startsWith('https://');
                      final isAsset = imagePath.startsWith('assets/');

                      ImageProvider provider;
                      if (isRemote) {
                        provider = NetworkImage(imagePath);
                      } else if (isAsset) {
                        provider = AssetImage(imagePath);
                      } else {
                        provider = FileImage(File(imagePath));
                      }

                      return CircleAvatar(
                        radius: 24,
                        backgroundImage: provider,
                        backgroundColor: Colors.grey.shade200,
                      );
                    },
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
                    // Refresh setelah kembali dari chat detail
                    await _loadThreads();
                    if (mounted) setState(() {});
                  },
                );
              },
            ),
    );
  }
}
