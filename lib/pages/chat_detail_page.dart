import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/chat_data.dart';
import '../data/auth_data.dart';
import '../data/venue_data.dart';

class ChatDetailPage extends StatefulWidget {
  final String username;
  final String venueName;
  final String role; // Need role to determine perspective

  const ChatDetailPage({
    super.key,
    required this.username,
    required this.venueName,
    this.role = 'End User', // default for backward compatibility
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;
  bool _isSending = false;
  bool _isLoading = true;

  late bool _isOwner;

  @override
  void initState() {
    super.initState();
    _isOwner = widget.role == 'Owner' || widget.role == 'Admin';
    _loadAndRefresh();
    // Polling setiap 3 detik untuk mendapatkan pesan baru secara real-time
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadAndRefresh(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAndRefresh({bool silent = false}) async {
    await GlobalChatData.loadThreads(
      filterUsername: widget.username,
      filterVenueName: widget.venueName,
    );
    await GlobalChatData.markReadOnline(
      username: widget.username,
      venueName: widget.venueName,
      isOwner: _isOwner,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (!silent) _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final String sender = _isOwner ? 'owner' : widget.username;
    final String text = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    await GlobalChatData.sendMessage(
      username: widget.username,
      venueName: widget.venueName,
      sender: sender,
      text: text,
      isOwner: _isOwner,
    );

    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = _isOwner ? widget.username : widget.venueName;
    final thread = GlobalChatData.getThread(widget.username, widget.venueName);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Builder(
              builder: (context) {
                String? imagePath;
                IconData fallbackIcon = Icons.person;
                
                if (_isOwner) {
                  imagePath = GlobalAuthData.getAccount(widget.username)?.profileImagePath;
                  fallbackIcon = Icons.person;
                } else {
                  final venue = GlobalVenueData.venues.firstWhere(
                    (v) => v['name'] == widget.venueName,
                    orElse: () => <String, dynamic>{},
                  );
                  imagePath = venue['image']?.toString();
                  fallbackIcon = Icons.stadium;
                }

                if (imagePath == null || imagePath.isEmpty) {
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(fallbackIcon, color: AppColors.primary, size: 18),
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
                  radius: 18,
                  backgroundImage: provider,
                  backgroundColor: Colors.grey.shade200,
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () {
            GlobalChatData.markReadOnline(
              username: widget.username,
              venueName: widget.venueName,
              isOwner: _isOwner,
            );
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : thread.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pesan.\nMulai percakapan!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: thread.messages.length,
                        itemBuilder: (context, index) {
                          final message = thread.messages[index];

                          // If I am owner, my messages have sender == 'owner'
                          // If I am user, my messages have sender == widget.username
                          final bool isMe = _isOwner
                              ? message.sender == 'owner'
                              : message.sender == widget.username;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                 if (!isMe)
                                   Builder(
                                     builder: (context) {
                                       String? imgPath;
                                       IconData fallback = Icons.person;
                                       if (_isOwner) {
                                         // Lawan bicara adalah user (message.sender)
                                         imgPath = GlobalAuthData.getAccount(message.sender)?.profileImagePath;
                                         fallback = Icons.person;
                                       } else {
                                         // Lawan bicara adalah venue (widget.venueName)
                                         final venue = GlobalVenueData.venues.firstWhere(
                                           (v) => v['name'] == widget.venueName,
                                           orElse: () => <String, dynamic>{},
                                         );
                                         imgPath = venue['image']?.toString();
                                         fallback = Icons.stadium;
                                       }
                                       return _buildChatAvatar(imagePath: imgPath, fallbackIcon: fallback);
                                     },
                                   )
                                else
                                  const SizedBox(width: 28),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? AppColors.primary
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft:
                                            const Radius.circular(16),
                                        topRight:
                                            const Radius.circular(16),
                                        bottomLeft:
                                            Radius.circular(isMe ? 16 : 4),
                                        bottomRight:
                                            Radius.circular(isMe ? 4 : 16),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.text,
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(message.timestamp),
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white70
                                                : Colors.grey.shade500,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                 if (isMe)
                                   Builder(
                                     builder: (context) {
                                       String? imgPath;
                                       IconData fallback = Icons.person;
                                       if (_isOwner) {
                                         // Saya adalah owner/venue (widget.venueName)
                                         final venue = GlobalVenueData.venues.firstWhere(
                                           (v) => v['name'] == widget.venueName,
                                           orElse: () => <String, dynamic>{},
                                         );
                                         imgPath = venue['image']?.toString();
                                         fallback = Icons.stadium;
                                       } else {
                                         // Saya adalah user (widget.username)
                                         imgPath = GlobalAuthData.getAccount(widget.username)?.profileImagePath;
                                         fallback = Icons.person;
                                       }
                                       return _buildChatAvatar(imagePath: imgPath, fallbackIcon: fallback);
                                     },
                                   )
                                else
                                  const SizedBox(width: 28),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSending
                      ? Colors.grey.shade400
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatAvatar({required String? imagePath, required IconData fallbackIcon}) {
    if (imagePath == null || imagePath.isEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(fallbackIcon, color: AppColors.primary, size: 14),
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
      radius: 14,
      backgroundImage: provider,
      backgroundColor: Colors.grey.shade200,
    );
  }
}
