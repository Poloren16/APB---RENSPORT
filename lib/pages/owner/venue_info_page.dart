import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../data/venue_data.dart';
import '../../models/review_model.dart';

class VenueInfoPage extends StatelessWidget {
  final Map<String, dynamic> venue;

  const VenueInfoPage({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final String venueName = venue['name'] ?? 'Detail Venue';
    final List<dynamic> courts = venue['courts'] ?? [];
    final List<dynamic> services = venue['services'] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Informasi Venue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue Basic Info
            _buildSectionTitle('Informasi Dasar'),
            _buildInfoCard([
              _buildInfoRow(Icons.stadium, 'Nama Venue', venueName),
              _buildInfoRow(Icons.location_on, 'Lokasi', venue['location'] ?? '-'),
              _buildInfoRow(Icons.sports_soccer, 'Tipe', venue['type'] ?? '-'),
              _buildInfoRow(Icons.payments, 'Harga Dasar', venue['price'] ?? '-'),
              _buildInfoRow(Icons.info, 'Status', venue['status'] ?? '-', 
                valueColor: (venue['status'] == 'Active') ? Colors.green : Colors.orange),
            ]),
            const SizedBox(height: 24),

            // Courts Info
            _buildSectionTitle('Daftar Lapangan (${courts.length})'),
            if (courts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('Belum ada lapangan yang terdaftar.', style: TextStyle(color: Colors.grey)),
              )
            else
              ...courts.map((court) => _buildSubCard(
                title: court['name'] ?? 'Lapangan',
                subtitle: 'Ukuran: ${court['size'] ?? '-'}',
                icon: Icons.grid_on,
              )),
            const SizedBox(height: 24),

            // Services Info
            _buildSectionTitle('Layanan Tambahan (${services.length})'),
            if (services.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('Belum ada layanan tambahan.', style: TextStyle(color: Colors.grey)),
              )
            else
              ...services.map((service) => _buildSubCard(
                title: service['name'] ?? 'Layanan',
                subtitle: 'Harga: Rp ${service['price']} / ${service['unit']}',
                icon: Icons.shopping_bag,
              )),
            const SizedBox(height: 24),

            // Reviews Summary
            _buildSectionTitle('Rating & Ulasan'),
            _buildReviewSummary(venueName),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
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

  Widget _buildSubCard({required String title, required String subtitle, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSummary(String venueName) {
    final rating = Review.getAverageRating(venueName);
    final count = Review.mockReviews.where((r) => r.venueName == venueName).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Text('dari 5.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (i) => Icon(
                  i < rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.orange, size: 20,
                )),
              ),
              const SizedBox(height: 4),
              Text('$count Total Ulasan', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
