import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class OwnerActivityPage extends StatefulWidget {
  final String username;

  const OwnerActivityPage({super.key, required this.username});

  @override
  State<OwnerActivityPage> createState() => _OwnerActivityPageState();
}

class _OwnerActivityPageState extends State<OwnerActivityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Bisnis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Ringkasan Pendapatan'),
            const SizedBox(height: 12),
            _buildIncomeSummary(),
            const SizedBox(height: 24),
            _buildSectionTitle('Daftar Transaksi'),
            const SizedBox(height: 12),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    );
  }

  Widget _buildIncomeSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1A3CC8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Saldo Tersedia', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('Rp 12.450.000', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Bulan Ini', 'Rp 4.2jt'),
              _buildSummaryItem('Minggu Ini', 'Rp 1.1jt'),
              _buildSummaryItem('Hari Ini', 'Rp 450rb'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTransactionList() {
    final transactions = [
      {'id': 'TX9921', 'user': 'Andi Pratama', 'court': 'Lap. A', 'date': '12 Apr', 'amount': 125000, 'status': 'Berhasil'},
      {'id': 'TX9922', 'user': 'Sari Wijaya', 'court': 'Lap. B', 'date': '12 Apr', 'amount': 250000, 'status': 'Berhasil'},
      {'id': 'TX9923', 'user': 'Budi Santoso', 'court': 'Lap. A', 'date': '11 Apr', 'amount': 125000, 'status': 'Berhasil'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: Icon(Icons.arrow_downward_rounded, color: Colors.green.shade600, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx['user'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${tx['court']} • ${tx['date']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rp ${tx['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(tx['status'] as String, style: TextStyle(fontSize: 11, color: Colors.green.shade600, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
