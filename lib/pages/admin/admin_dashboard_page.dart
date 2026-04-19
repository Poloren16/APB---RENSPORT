import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:rensius/theme/app_colors.dart';
import 'package:rensius/data/verification_data.dart';
import 'package:rensius/models/verification_model.dart';
import 'package:rensius/utils/alert_utils.dart';
import 'package:rensius/pages/login_page.dart';
import 'package:rensius/data/auth_data.dart';
import 'package:rensius/widgets/empty_state_widget.dart';
import 'dart:io';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _activeTab = 0; // 0: Overview, 1: Owner Verification, 2: Venue Verification
  
  // Pagination State
  final int _itemsPerPage = 5;
  int _userPage = 0;
  int _ownerPage = 0;
  int _ownerSubTab = 0; // 0: Verification, 1: Database

  @override
  void initState() {
    super.initState();
    _cleanupRejectedAccounts();
  }

  Future<void> _cleanupRejectedAccounts() async {
    // Remove accounts from GlobalAuthData that are currently marked as 'Rejected' in Verification Requests
    for (var req in GlobalVerificationData.requests) {
      if (req.status == 'Rejected' && req.username != null) {
        await GlobalAuthData.deleteAccount(req.username!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Pusat Manajemen Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopStats(),
          _buildTabSwitcher(),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppColors.primary,
      child: Row(
        children: [
          _buildHeaderStat('Total Akun', '${GlobalAuthData.accounts.where((a) => a.role == 'Owner').length}', Icons.people_alt),
          const SizedBox(width: 16),
          _buildHeaderStat('Menunggu', '${GlobalVerificationData.requests.where((r) => r.status == 'Pending').length}', Icons.pending_actions),
          const SizedBox(width: 16),
          _buildHeaderStat('Terverifikasi', '${GlobalVerificationData.requests.where((r) => r.status == 'Approved').length}', Icons.verified_user),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildTabItem(0, 'Ringkasan', Icons.dashboard_outlined),
            const SizedBox(width: 12),
            _buildTabItem(1, 'Manajemen User', Icons.people_outline_rounded),
            const SizedBox(width: 12),
            _buildTabItem(2, 'Manajemen Owner', Icons.business_center_outlined),
            const SizedBox(width: 12),
            _buildTabItem(3, 'Verifikasi Venue', Icons.stadium_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            if (!isActive)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
          border: Border.all(color: isActive ? AppColors.primary : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildAccountManagement('End User');
      case 2:
        return _buildOwnerManagementWithToggle();
      case 3:
        return _buildVerificationList('Venue');
      default:
        return Container();
    }
  }

  Widget _buildOverview() {
    return const EmptyStateWidget(
      message: 'Tidak ada aktivitas baru.',
      subMessage: 'Statistik akan muncul saat aplikasi digunakan.',
    );
  }

  Widget _buildVerificationList(String type) {
    final filtered = GlobalVerificationData.requests.where((r) => r.type == type).toList();

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        message: 'Permintaan verifikasi $type tidak ditemukan',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final req = filtered[index];
        return _buildVerificationCard(req);
      },
    );
  }

  Widget _buildVerificationCard(VerificationRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(req.applicantName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.type == 'Owner' ? req.applicantName : req.venueName ?? 'Venue Name',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(req.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                _buildStatusBadge(req.status),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Tanggal: ${req.submittedAt.day}/${req.submittedAt.month}/${req.submittedAt.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                TextButton(
                  onPressed: () => _showDetailDialog(req),
                  child: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'Approved') color = Colors.green;
    if (status == 'Rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildErrorImage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 48, color: Colors.grey),
          Text('Image could not be loaded', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _showDetailDialog(VerificationRequest req) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(req.type == 'Owner' ? 'Detail Owner' : 'Detail Venue'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Nama Pemohon', req.applicantName),
                if (req.username != null) _buildDetailRow('Username Akun', req.username!),
                if (req.phoneNumber != null) _buildDetailRow('Nomor WhatsApp', req.phoneNumber!),
                if (req.type == 'Venue') _buildDetailRow('Nama Venue', req.venueName ?? '-'),
                _buildDetailRow('NIK', req.nik),
                _buildDetailRow('NPWP', req.npwp),
                if (req.type == 'Venue') _buildDetailRow('Alamat', req.venueAddress ?? '-'),
                const SizedBox(height: 16),
                const Text('Lampiran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (req.documentUrl.isNotEmpty && 
                          (req.documentUrl.contains('/') || req.documentUrl.contains('\\')))
                        Positioned.fill(
                          child: kIsWeb
                              ? Image.network(
                                  req.documentUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                                )
                              : Image.file(
                                  File(req.documentUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                                ),
                        )
                      else if (req.documentUrl.startsWith('assets/'))
                        Positioned.fill(
                          child: Image.asset(req.documentUrl, fit: BoxFit.cover),
                        )
                      else
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 48, color: Colors.grey),
                            Text('Dokumen tidak tersedia', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (req.status == 'Pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _showRejectDialog(req);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close Detail Dialog first
                      await _handleStatusChange(req, 'Approved');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Setujui'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.lock_outline),
                label: Text('Permintaan sudah ${req.status}'),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: Colors.grey.shade100,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showRejectDialog(VerificationRequest req) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alasan Penolakan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'misal: foto identitas tidak jelas'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close Reject Dialog first
              await _handleStatusChange(req, 'Rejected', reason: controller.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kirim Penolakan'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStatusChange(VerificationRequest req, String newStatus, {String? reason}) async {
    // Show a small processing snackbar or loading state if needed
    // But for this mock, await the save directly
    await GlobalVerificationData.updateRequestStatus(req.id, newStatus, reason: reason);

    // If Approved, create the actual login account
    if (newStatus == 'Approved' && req.username != null) {
      await GlobalAuthData.registerAccount(UserAccount(
        username: req.username!,
        password: req.password ?? '123456',
        role: req.type,
        applicantName: req.applicantName,
        email: req.email ?? '',
        phoneNumber: req.phoneNumber ?? '',
      ));
    } 
    // If Rejected, make sure no account exists (cleanup)
    else if (newStatus == 'Rejected' && req.username != null) {
      await GlobalAuthData.deleteAccount(req.username!);
    }

    if (mounted) {
      setState(() {});
      // Clear SnackBar if already showing
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Simulated Notification
      _showNotificationSimulation(req, newStatus);
      
      AlertUtils.showResultDialog(
        context,
        isSuccess: true,
        title: newStatus == 'Approved' ? 'Disetujui' : 'Ditolak',
        message: 'Permintaan ${req.applicantName} telah $newStatus.',
      );
    }
  }

  // ACCOUNT MANAGEMENT (NEW)
  Widget _buildAccountManagement(String role) {
    // Filter accounts by role
    final allForRole = GlobalAuthData.accounts.where((a) => a.role == role).toList();
    
    // Pagination logic
    final int currentPage = role == 'End User' ? _userPage : _ownerPage;
    final int startIndex = currentPage * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage < allForRole.length) 
        ? startIndex + _itemsPerPage 
        : allForRole.length;
    
    final pagedItems = (startIndex < allForRole.length) 
        ? allForRole.sublist(startIndex, endIndex) 
        : <UserAccount>[];
        
    final int totalPages = (allForRole.length / _itemsPerPage).ceil();

    if (allForRole.isEmpty) {
      return EmptyStateWidget(
        message: 'Tidak ada akun ditemukan dengan role: $role',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pagedItems.length,
            itemBuilder: (context, index) {
              final acc = pagedItems[index];
              return _buildAccountCard(acc);
            },
          ),
        ),
        // Pagination Controls
        if (totalPages > 1)
          _buildPaginationFooter(role, currentPage, totalPages),
      ],
    );
  }

  Widget _buildAccountCard(UserAccount acc) {
    // Admin cannot be deleted
    bool isDeletable = acc.role != 'Admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(
              acc.role == 'Owner' ? Icons.business_center : Icons.person,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acc.applicantName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text('@${acc.username}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          if (isDeletable)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  onPressed: () => _showEditAccountDialog(acc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDeleteAccount(acc),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(String role, int currentPage, int totalPages) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 0 
                ? () => setState(() => role == 'End User' ? _userPage-- : _ownerPage--)
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Text('Halaman ${currentPage + 1} dari $totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1 
                ? () => setState(() => role == 'End User' ? _userPage++ : _ownerPage++)
                : null,
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(UserAccount acc) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Hapus Akun?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Apakah Anda yakin ingin menghapus akun ${acc.applicantName} (@${acc.username})? Tindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        
                        // Sync with verification records
                        final reqIndex = GlobalVerificationData.requests.indexWhere((r) => r.username == acc.username);
                        if (reqIndex != -1) {
                          await GlobalVerificationData.updateRequestStatus(
                            GlobalVerificationData.requests[reqIndex].id,
                            'Rejected',
                            reason: 'Akun dihapus oleh Admin',
                          );
                        }
                        
                        await GlobalAuthData.deleteAccount(acc.username);
                        setState(() {}); // Refresh list
                        if (mounted) {
                          AlertUtils.showToast(context, 'Akun berhasil dihapus');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAccountDialog(UserAccount acc) {
    final TextEditingController nameController = TextEditingController(text: acc.applicantName);
    final TextEditingController passwordController = TextEditingController(text: acc.password);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              width: double.infinity,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('Edit Akun', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('@${acc.username}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildStyledTextField(
                    controller: nameController,
                    label: 'Nama Lengkap',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildStyledTextField(
                    controller: passwordController,
                    label: 'Password Baru',
                    icon: Icons.lock_outline_rounded,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.grey.shade600,
                          ),
                          child: const Text('Batal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await GlobalAuthData.updateAccount(acc.username, newName: nameController.text, newPassword: passwordController.text);
                            setState(() {}); // Refresh list
                            if (mounted) {
                              AlertUtils.showToast(context, 'Akun berhasil diupdate');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 4,
                            shadowColor: AppColors.primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildOwnerManagementWithToggle() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(child: _buildSubTab(0, 'Owner List', Icons.storage_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildSubTab(1, 'Owner Requests', Icons.pending_actions)),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: _ownerSubTab == 0 ? _buildAccountManagement('Owner') : _buildVerificationList('Owner'),
        ),
      ],
    );
  }

  Widget _buildSubTab(int index, String label, IconData icon) {
    bool isActive = _ownerSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _ownerSubTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? AppColors.primary : Colors.grey, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? AppColors.primary : Colors.grey, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  void _showNotificationSimulation(VerificationRequest req, String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: status == 'Approved' ? Colors.green.shade800 : Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🔄 SIMULATION: $status notification sent to ${req.phoneNumber ?? req.email}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
