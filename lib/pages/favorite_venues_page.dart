import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_colors.dart';
import '../data/venue_data.dart';
import '../models/review_model.dart';
import '../widgets/empty_state_widget.dart';
import 'booking_page.dart';

class FavoriteVenuesPage extends StatefulWidget {
  final String username;
  final String role;

  const FavoriteVenuesPage({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<FavoriteVenuesPage> createState() => _FavoriteVenuesPageState();
}

class _FavoriteVenuesPageState extends State<FavoriteVenuesPage> {
  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp$formatted';
  }

  IconData _getSportIcon(String sportType) {
    final clean = sportType.toLowerCase().trim();
    if (clean.contains('futsal') || clean.contains('sepak') || clean.contains('bola') || clean.contains('soccer') || clean.contains('mini')) {
      return Icons.sports_soccer;
    } else if (clean.contains('badminton') || clean.contains('bulu') || clean.contains('tangkis') || clean.contains('tennis') || clean.contains('tenis')) {
      return Icons.sports_tennis;
    } else if (clean.contains('basket') || clean.contains('ball')) {
      return Icons.sports_basketball;
    } else if (clean.contains('voli') || clean.contains('volleyball')) {
      return Icons.sports_volleyball;
    }
    return Icons.sports_soccer; // default fallback
  }

  String _getPriceDisplay(Map<String, dynamic> venue) {
    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == venue['name']);
    final Map<String, dynamic> activeVenue = venueResults.isNotEmpty ? venueResults.first : venue;

    final courts = activeVenue['courts'] as List<dynamic>? ?? [];
    final prices = <int>[];
    
    for (final c in courts) {
      final cMap = Map<String, dynamic>.from(c as Map);
      
      // 1. Ambil harga harian (priceDay)
      final priceDay = cMap['priceDay'] as Map? ?? {};
      for (final val in priceDay.values) {
        final v = val?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
        if (v.isNotEmpty) {
          final n = int.tryParse(v);
          if (n != null && n > 0) prices.add(n);
        }
      }
      
      // 2. Ambil harga per jam (pricePerSlot) jika mode perSlot aktif
      final priceMode = cMap['priceMode'] ?? 'perDay';
      if (priceMode == 'perSlot') {
        final pricePerSlot = cMap['pricePerSlot'] as Map? ?? {};
        for (final val in pricePerSlot.values) {
          final v = val?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
          if (v.isNotEmpty) {
            final n = int.tryParse(v);
            if (n != null && n > 0) prices.add(n);
          }
        }
      }
    }

    if (prices.isEmpty) {
      final priceVal = activeVenue['price'];
      if (priceVal == null) return 'Hubungi Pengelola';
      if (priceVal is int) return _formatCurrency(priceVal);
      final parsed = int.tryParse(priceVal.toString().replaceAll(RegExp(r'[^0-9]'), ''));
      return parsed != null ? _formatCurrency(parsed) : priceVal.toString();
    }
    
    prices.sort();
    final min = prices.first;
    final max = prices.last;
    return min == max ? '${_formatCurrency(min)}/jam' : '${_formatCurrency(min)} - ${_formatCurrency(max)}/jam';
  }

  @override
  Widget build(BuildContext context) {
    final favorites = GlobalVenueData.favorites;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Venue Favorit Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: favorites.isEmpty
          ? const EmptyStateWidget(
              message: 'Belum ada venue favorit',
              subMessage: 'Tandai venue favorit Anda agar dapat menemukannya di sini dengan mudah!',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final venue = favorites[index];
                return _buildFavoriteCard(venue);
              },
            ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> venue) {
    final String venueName = venue['name'] ?? 'Unknown Venue';
    final String imagePath = venue['image']?.toString() ?? '';
    final String venueType = venue['type']?.toString() ?? 'Olahraga';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingPage(
                  username: widget.username,
                  venueName: venueName,
                  venueType: venueType,
                  venueAddress: venue['address'] ?? venue['location'] ?? '',
                  venueHours: venue['hours'] ?? '06:00 - 22:00',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: Builder(builder: (context) {
                      if (imagePath.isEmpty) {
                        return Icon(_getSportIcon(venueType), size: 40, color: Colors.grey);
                      }
                      final isRemote = imagePath.startsWith('http://') || imagePath.startsWith('https://');
                      final isAsset = imagePath.startsWith('assets/');
                      try {
                        if (isRemote) {
                          return Image.network(
                            imagePath,
                            width: 100, height: 100, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(_getSportIcon(venueType), size: 40, color: Colors.grey),
                          );
                        } else if (isAsset) {
                          return Image.asset(
                            imagePath,
                            width: 100, height: 100, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(_getSportIcon(venueType), size: 40, color: Colors.grey),
                          );
                        } else {
                          return Image.file(
                            File(imagePath),
                            width: 100, height: 100, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(_getSportIcon(venueType), size: 40, color: Colors.grey),
                          );
                        }
                      } catch (e) {
                        return Icon(_getSportIcon(venueType), size: 40, color: Colors.grey);
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venueName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            Review.getAverageRating(venueName).toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${Review.mockReviews.where((r) => r.venueName == venueName).length} ulasan)',
                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              venue['location'] ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _getPriceDisplay(venue),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark, color: Colors.orange),
                  onPressed: () {
                    setState(() {
                      GlobalVenueData.toggleFavorite(venue);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
