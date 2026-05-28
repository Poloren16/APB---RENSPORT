import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../theme/app_colors.dart';
import '../../data/venue_data.dart';
import '../../pages/venue_page.dart';
import '../../pages/booking_page.dart';

class VenueContactSection extends StatefulWidget {
  final String username;
  final String role;
  final String venueType;
  final String currentVenueName;
  final String Function(int) formatCurrency;

  const VenueContactSection({
    super.key,
    required this.username,
    required this.role,
    required this.venueType,
    required this.currentVenueName,
    required this.formatCurrency,
  });

  @override
  State<VenueContactSection> createState() => _VenueContactSectionState();
}

class _VenueContactSectionState extends State<VenueContactSection> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

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
    required String imagePath,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingPage(
            username: widget.username,
            venueName: name,
            venueType: types,
            venueAddress: address,
          ),
        ),
      ),
      child: Container(
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
          // Foto venue nyata atau gradient fallback
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 80, width: double.infinity,
              child: imagePath.isNotEmpty
                  ? Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientPlaceholder(),
                    )
                  : _gradientPlaceholder(),
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
                      price > 0 ? widget.formatCurrency(price) : 'Hubungi Pengelola',
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
     ),
    );
  }

  Widget _gradientPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
    );
  }


  @override
  Widget build(BuildContext context) {
    // Get recommendations matching the current venue's sport type
    List<Map<String, dynamic>> allMatches = GlobalVenueData.venues
        .where((v) => 
          v['type'] == widget.venueType && 
          v['name'] != widget.currentVenueName
        ).toList();

    bool isFallback = false;
    // Fallback to all venues if no matches for the same sport
    if (allMatches.isEmpty) {
      isFallback = true;
      allMatches = GlobalVenueData.venues
          .where((v) => v['name'] != widget.currentVenueName)
          .toList();
    }

    // Limit the displayed recommendations to 10
    final List<Map<String, dynamic>> recommendations = allMatches.take(10).toList();

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
                  const Text('Kontak Venue',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      )),
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
                      onTap: () => _launchURL('https://wa.me/6281279098707')),
                  _contactButton(
                      icon: Icons.camera_alt,
                      iconColor: const Color(0xFFE1306C),
                      label: 'Instagram',
                      onTap: () => _launchURL('https://www.instagram.com/polorenn16/')),
                ],
              ),
            ],
          ),
        ),

        Container(height: 8, color: AppColors.background),

        // ── Venue Recommendation ─────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rekomendasi Venue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        )),
                    if (_currentPage == recommendations.length - 1 && recommendations.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VenuePage(
                                username: widget.username,
                                role: widget.role,
                                initialCategory: isFallback ? 'Semua' : widget.venueType,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded,
                              size: 18, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: recommendations.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    // Harga minimum dari semua priceDay semua courts
                    final venue = recommendations[index];
                    int priceVal = 0;
                    final courts = venue['courts'] as List<dynamic>? ?? [];
                    for (final c in courts) {
                      final priceDay = c['priceDay'] as Map? ?? {};
                      for (final val in priceDay.values) {
                        final n = int.tryParse(val?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '');
                        if (n != null && n > 0 && (priceVal == 0 || n < priceVal)) priceVal = n;
                      }
                    }
                    // Fallback ke venue['price'] jika tidak ada
                    if (priceVal == 0 && venue['price'] is int) priceVal = venue['price'];

                    final imgPath = venue['image']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _venueRecommendationCard(
                          name: venue['name'] ?? 'Unknown',
                          address: venue['location'] ?? 'Unknown',
                          types: venue['type'] ?? 'Sports',
                          price: priceVal,
                          distance: '3 km',
                          imagePath: imgPath),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Paging Indicators (Dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(recommendations.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 100),
      ],
    );
  }
}
