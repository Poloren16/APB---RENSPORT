import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AlertUtils {
  /// Sanitize pesan error teknis dari backend/exception agar tidak tampil ke user.
  /// Hanya panggil ini untuk pesan yang berasal dari exception/catch block.
  /// Pesan validasi user-facing TIDAK perlu melalui fungsi ini.
  static String sanitizeErrorMessage(String originalMessage) {
    final lower = originalMessage.toLowerCase();
    
    // Hanya filter pesan yang jelas bersifat teknis/backend
    if (lower.contains('supabase') || 
        lower.contains('postgrest') || 
        lower.contains('socketexception') || 
        lower.contains('failed host') || 
        lower.contains('http') ||
        lower.contains('database') ||
        lower.contains('sql') ||
        lower.contains('relation') ||
        lower.contains('uuid') ||
        lower.contains('api') ||
        lower.contains('timeout') ||
        lower.contains('server') ||
        lower.contains('exception') ||
        lower.contains('nullpointer') ||
        lower.contains('bad request') ||
        lower.contains('internal server error') ||
        lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials') ||
        lower.contains('jwt') ||
        lower.contains('midtrans') || 
        lower.contains('snap') || 
        lower.contains('gateway') || 
        lower.contains('refused') ||
        lower.contains('unauthorized') ||
        lower.contains('forbidden') ||
        lower.contains('dns') ||
        lower.contains('socket') ||
        lower.contains('status code') ||
        lower.contains('null check') ||
        lower.contains('overflow') ||
        lower.contains('unhandled') ||
        lower.contains('assertion') ||
        lower.contains('stacktrace')) {
      
      if (lower.contains('socketexception') || 
          lower.contains('failed host') ||
          lower.contains('dns') ||
          lower.contains('socket') ||
          lower.contains('refused') ||
          lower.contains('timeout')) {
        return 'Koneksi terganggu. Periksa koneksi internet Anda dan coba lagi.';
      }
      if (lower.contains('midtrans') || 
          lower.contains('snap') || 
          lower.contains('gateway')) {
        return 'Gagal memproses pembayaran. Silakan coba beberapa saat lagi atau hubungi pihak venue.';
      }
      if (lower.contains('database') || 
          lower.contains('sql') || 
          lower.contains('relation') ||
          lower.contains('postgrest')) {
        return 'Koneksi terganggu. Silakan coba beberapa saat lagi.';
      }
      if (lower.contains('server') || 
          lower.contains('internal server error') ||
          lower.contains('bad request')) {
        return 'Koneksi terganggu. Silakan coba beberapa saat lagi.';
      }
      if (lower.contains('invalid login credentials') || 
          lower.contains('invalid_credentials') || 
          lower.contains('jwt') ||
          lower.contains('unauthorized') ||
          lower.contains('forbidden')) {
        return 'Gagal memverifikasi akun Anda. Periksa nama pengguna dan kata sandi Anda.';
      }
      return 'Terjadi kendala pada aplikasi. Mohon coba beberapa saat lagi.';
    }
    
    return originalMessage;
  }

  static void showResultDialog(
    BuildContext context, {
    required bool isSuccess,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    IconData? customIcon,
    Color? customColor,
    /// Set true jika pesan sudah ramah pengguna (dari validasi input).
    /// Set false (default) jika pesan berasal dari catch/exception (akan disanitize).
    bool isUserFacing = false,
  }) {
    String sanitizedMessage = message;
    if (!isSuccess) {
      debugPrint('DEVELOPER ERROR LOG: $message');
      // Hanya sanitize jika pesan bukan dari validasi user (bisa mengandung info teknis)
      sanitizedMessage = isUserFacing ? message : sanitizeErrorMessage(message);
    }
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (customColor ?? (isSuccess ? Colors.green : Colors.red)).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      customIcon ?? (isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded),
                      color: customColor ?? (isSuccess ? Colors.green : Colors.red),
                      size: 72,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sanitizedMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (onConfirm != null) onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customColor ?? (isSuccess ? Colors.green : Colors.red),
                        foregroundColor: (customColor == Colors.amber || customColor == Colors.yellow) ? Colors.black87 : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Oke, Dimengerti!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void showToast(BuildContext context, String message, {bool isSuccess = true, bool isUserFacing = false}) {
    String sanitizedMessage = message;
    if (!isSuccess) {
      debugPrint('DEVELOPER TOAST ERROR LOG: $message');
      sanitizedMessage = isUserFacing ? message : sanitizeErrorMessage(message);
    }
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: sanitizedMessage,
        isSuccess: isSuccess,
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  static void showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 48),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onConfirm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Ya, Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isSuccess;

  const _ToastWidget({required this.message, required this.isSuccess});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isSuccess ? Colors.green.shade600 : Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
