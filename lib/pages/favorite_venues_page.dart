import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    final favorites = GlobalVenueData.favorites;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Favorite Venues',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: favorites.isEmpty
          ? const EmptyStateWidget(
              message: 'No favorite venues yet',
              subMessage: 'Bookmark your favorite venues to find them here easily!',
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
                  venueType: venue['type'] ?? 'Sports',
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
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          venue['distance'] ?? '3 km',
                          style: const TextStyle(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                  ],
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
                            '(${Review.mockReviews.where((r) => r.venueName == venueName).length} reviews)',
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
                      Text(
                        venue['price'] ?? 'Contact Manager',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
