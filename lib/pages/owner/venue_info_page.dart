import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/review_model.dart';

class VenueInfoPage extends StatelessWidget {
  final Map<String, dynamic> venue;

  const VenueInfoPage({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final String venueName = venue['name'] ?? 'Detail Venue';
    final List<dynamic> courts = venue['courts'] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Informasi Venue',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Informasi Lokasi Detail
            _buildSectionTitle('Lokasi & Alamat'),
            _buildInfoCard([
              _buildInfoRow(Icons.stadium, 'Nama Venue', venueName),
              _buildInfoRow(Icons.map, 'Provinsi', venue['provinsi'] ?? '-'),
              _buildInfoRow(Icons.location_city, 'Kota', venue['location'] ?? '-'),
              _buildInfoRow(Icons.add_location_alt_outlined, 'Jalan', venue['address'] ?? '-'),
              _buildInfoRow(Icons.more_horiz, 'Detail', venue['dll'] ?? '-'),
              _buildInfoRow(Icons.info_outline, 'Status', venue['status'] ?? '-',
                  valueColor: (venue['status'] == 'Aktif') ? Colors.green : Colors.orange),
            ]),
            const SizedBox(height: 24),

            // 2. Rincian Per Lapangan (Termasuk Rating & Ulasan)
            _buildSectionTitle('Daftar Lapangan (${courts.length})'),
            if (courts.isEmpty)
              const Text('Belum ada lapangan terdaftar.', style: TextStyle(color: Colors.grey))
            else
              ...courts.asMap().entries.map((entry) => _buildDetailedCourtCard(entry.value, venueName)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedCourtCard(Map<String, dynamic> court, String venueName) {
    final Map<String, dynamic> priceDay = court['priceDay'] ?? {};
    final List<dynamic> services = court['services'] ?? [];
    final String courtName = court['name'] ?? 'Lapangan';

    // Fetch reviews specifically for this court (simulated by venueName)
    final rating = Review.getAverageRating(venueName);
    final reviews = Review.mockReviews.where((r) => r.venueName == venueName).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Lapangan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.grid_on, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(courtName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                // --- RATING DI HEADER LAPANGAN ---
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spesifikasi
                _buildSmallInfo('Tipe: ${court['type']} | ${court['courtCategory']}'),
                _buildSmallInfo('Lantai: ${court['floorType']}'),
                _buildSmallInfo('Ukuran: ${court['size']}'),
                _buildSmallInfo('Fasilitas: ${court['facility']}'),
                const Divider(height: 24),

                // Harga Harian
                const Text('Harga Sewa (Per Jam):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDayPriceGrid(priceDay),

                if (services.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('Layanan Tambahan:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...services.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('• ${s['name']}', style: const TextStyle(fontSize: 12)),
                        Text('Rp ${s['price']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                ],

                const Divider(height: 24),
                // --- ULASAN PER LAPANGAN (SECTION) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ulasan & Rating',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('${reviews.length} Ulasan', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                if (reviews.isEmpty)
                  const Text('Belum ada ulasan untuk lapangan ini.', style: TextStyle(fontSize: 11, color: Colors.grey))
                else
                  ...reviews.take(2).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(r.username, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Row(children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star : Icons.star_border, size: 10, color: Colors.orange))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(r.comment, style: const TextStyle(fontSize: 11, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPriceGrid(Map<String, dynamic> priceDay) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: priceDay.entries.map((e) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(e.key, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(e.value.toString().isEmpty ? 'N/A' : 'Rp ${e.value}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSmallInfo(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
