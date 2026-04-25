import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

import '../../data/venue_data.dart';
import '../../utils/booking_utils.dart';
import '../booking_history.dart';
import '../../widgets/empty_state_widget.dart';

class OwnerActivityPage extends StatefulWidget {
  final String username;

  const OwnerActivityPage({super.key, required this.username});

  @override
  State<OwnerActivityPage> createState() => _OwnerActivityPageState();
}

class _OwnerActivityPageState extends State<OwnerActivityPage> {
  String _selectedVenue = 'Semua';

  /// Returns only transactions belonging to this owner's venues.
  /// If [venueName] is provided and not 'Semua', further filters by that venue.
  List<Map<String, dynamic>> _getOwnerTransactions([String? venueName]) {
    final ownerVenueNames = GlobalVenueData.getVenuesForOwner(widget.username)
        .map((v) => v['name'] as String)
        .toSet();

    final all = [...BookingHistoryPage.mockHistory, ...BookingHistoryPage.mockPastHistory];
    final ownerTx = all.where((b) => ownerVenueNames.contains(b['venueName'])).toList();

    final filter = venueName ?? _selectedVenue;
    if (filter == 'Semua') return ownerTx;
    return ownerTx.where((b) => b['venueName'] == filter).toList();
  }

  int _calculateOwnerRevenue(String period) {
    final all = _getOwnerTransactions();
    final total = all.fold(0, (sum, b) => sum + (int.tryParse(b['price'].toString()) ?? 0));
    if (period == 'Bulan Ini') return (total * 0.8).toInt();
    if (period == 'Minggu Ini') return (total * 0.3).toInt();
    if (period == 'Hari Ini') return (total * 0.1).toInt();
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Bisnis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVenueFilter(),
            const SizedBox(height: 24),
            _buildSectionTitle('Ringkasan Pendapatan (Bulan Ini)'),
            const SizedBox(height: 12),
            _buildIncomeSummary(),
            const SizedBox(height: 24),
            _buildInsightsSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Tren Regresi Pendapatan'),
            const SizedBox(height: 12),
            _buildChartSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Aktivitas Transaksi'),
            const SizedBox(height: 12),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    final transactions = _getOwnerTransactions(_selectedVenue);
    Map<String, int> courtCounts = {};
    for (var tx in transactions) {
      String c = tx['courtName'] ?? 'Tidak Diketahui';
      courtCounts[c] = (courtCounts[c] ?? 0) + 1;
    }
    
    String topCourt = 'Belum ada data';
    int maxCount = 0;
    courtCounts.forEach((k, v) {
      if (v > maxCount) {
        maxCount = v;
        topCourt = k;
      }
    });

    return Row(
      children: [
        Expanded(
          child: _buildInsightCard(
            'Lapangan Populer',
            topCourt,
            Icons.star_rounded,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInsightCard(
            'Total Pemesanan',
            '${transactions.length} Pesanan',
            Icons.poll_rounded,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildVenueFilter() {
    // Only show venues belonging to this owner
    final ownerVenueNames = GlobalVenueData.getVenuesForOwner(widget.username)
        .map((v) => v['name'] as String)
        .toList();
    final venues = ['Semua', ...ownerVenueNames];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedVenue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          items: venues.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedVenue = val);
          },
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
    final int today = _calculateOwnerRevenue('Hari Ini');
    final int week = _calculateOwnerRevenue('Minggu Ini');
    final int month = _calculateOwnerRevenue('Bulan Ini');
    final int total = _calculateOwnerRevenue('Total');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pendapatan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(total), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Bulan Ini', _formatShortCurrency(month), Icons.arrow_upward, Colors.greenAccent),
              _buildSummaryItem('Minggu Ini', _formatShortCurrency(week), Icons.trending_up, Colors.orangeAccent),
              _buildSummaryItem('Hari Ini', _formatShortCurrency(today), Icons.today, Colors.cyanAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 10),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChartSection() {
    final data = BookingUtils.getWeeklyDistribution(venueName: _selectedVenue);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kinerja Mingguan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              GestureDetector(
                onTap: _showDetailReport,
                child: const Text('Lihat Detail', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold))
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: LineChartPainter(data),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                .map((d) => Text(d, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showDetailReport() {
    final transactions = _getOwnerTransactions(_selectedVenue).reversed.take(7).toList();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detail Pendapatan Harian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            if (transactions.isEmpty) 
               const EmptyStateWidget(
                message: 'Tidak ada rincian data tersedia',
                subMessage: 'Transaksi akan muncul di sini setelah ada pesanan masuk.',
              )
            else
              ...transactions.map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx['courtName'] ?? 'Lapangan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(tx['date'] ?? '-', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text(_formatCurrency(int.tryParse(tx['price'].toString()) ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              )).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = _getOwnerTransactions(_selectedVenue).reversed.toList();

    if (transactions.isEmpty) {
      return const EmptyStateWidget(
        message: 'Belum ada transaksi',
        subMessage: 'Data aktivitas transaksi venue Anda akan ditampilkan di sini.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final bool isSuccess = tx['status'] == 'Confirmed' || tx['status'] == 'Pembayaran Berhasil';
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green.shade50 : Colors.blue.shade50,
                  shape: BoxShape.circle
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.access_time_filled_rounded,
                  color: isSuccess ? Colors.green.shade600 : Colors.blue.shade600,
                  size: 20
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx['courtName'] ?? 'Lapangan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${tx['venueName']} • ${tx['date']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatCurrency(int.tryParse(tx['price'].toString()) ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSuccess ? Colors.green.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSuccess ? 'Berhasil' : 'Diproses',
                      style: TextStyle(fontSize: 10, color: isSuccess ? Colors.green.shade700 : Colors.blue.shade700, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp$formatted';
  }

  String _formatShortCurrency(int amount) {
    if (amount >= 1000000) return 'Rp ${(amount / 1000000).toStringAsFixed(1)}JT';
    if (amount >= 1000) return 'Rp ${(amount / 1000).toStringAsFixed(0)}RB';
    return 'Rp $amount';
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    double xStep = size.width / (data.length - 1);
    
    for (int i = 0; i < data.length; i++) {
       double x = i * xStep;
       double y = size.height - (data[i] * size.height * 0.8);
       
       if (i == 0) {
         path.moveTo(x, y);
         fillPath.moveTo(x, size.height);
         fillPath.lineTo(x, y);
       } else {
         // Smooth curve using cubicTo
         double prevX = (i - 1) * xStep;
         double prevY = size.height - (data[i - 1] * size.height * 0.8);
         path.cubicTo(
           prevX + xStep / 2, prevY,
           x - xStep / 2, y,
           x, y,
         );
         fillPath.cubicTo(
           prevX + xStep / 2, prevY,
           x - xStep / 2, y,
           x, y,
         );
       }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()..color = AppColors.primary..style = PaintingStyle.stroke..strokeWidth = 2;

    for (int i = 0; i < data.length; i++) {
      double x = i * xStep;
      double y = size.height - (data[i] * size.height * 0.8);
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
