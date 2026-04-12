import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class VenueContactSection extends StatelessWidget {
  final String Function(int) formatCurrency;

  const VenueContactSection({
    super.key,
    required this.formatCurrency,
  });

  Widget _contactButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _venueRecommendationCard({
    required String name,
    required String address,
    required String types,
    required int price,
    required String distance,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0E21A0).withValues(alpha: 0.8),
                  const Color(0xFF1A3CC8).withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Center(
              child: Icon(Icons.sports_soccer,
                  color: Colors.white.withValues(alpha: 0.5), size: 32),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.sports_tennis,
                        size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        types,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Harga mulai dari',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatCurrency(price),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      distance,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Venue Contact ───────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Venue Contact',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      )),
                  GestureDetector(
                    onTap: () {},
                    child: const Row(children: [
                      Text('Selengkapnya Tentang Venue',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right,
                          size: 15, color: AppColors.primary),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _contactButton(
                      icon: Icons.chat,
                      iconColor: const Color(0xFF25D366),
                      label: 'WhatsApp',
                      onTap: () {}),
                  _contactButton(
                      icon: Icons.camera_alt,
                      iconColor: const Color(0xFFE1306C),
                      label: 'Instagram',
                      onTap: () {}),
                  _contactButton(
                      icon: Icons.qr_code,
                      iconColor: AppColors.textPrimary,
                      label: 'QR Code',
                      onTap: () {}),
                ],
              ),
            ],
          ),
        ),

        Container(height: 8, color: AppColors.background),

        // ── Rekomendasi Venue ─────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 20, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rekomendasi Venue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        )),
                    GestureDetector(
                      onTap: () {},
                      child: const Row(children: [
                        Text('Lihat lebih banyak',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                        Icon(Icons.chevron_right,
                            size: 15, color: AppColors.primary),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _venueRecommendationCard(
                        name: 'Persada Sports Facilities',
                        address: 'Jl. Raya Protokol Ha...',
                        types: 'Mini Soccer, Tenis, Pad...',
                        price: 225000,
                        distance: '114 km'),
                    _venueRecommendationCard(
                        name: 'GOR Arcamanik',
                        address: 'Jl. Pacuan Kuda No.8...',
                        types: 'Badminton, Basket...',
                        price: 75000,
                        distance: '8 km'),
                    _venueRecommendationCard(
                        name: 'Ujung Berung Sports Center',
                        address: 'Jl. AH Nasution No.23...',
                        types: 'Futsal, Tenis Meja...',
                        price: 90000,
                        distance: '12 km'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 100),
      ],
    );
  }
}
