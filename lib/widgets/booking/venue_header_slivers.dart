import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/review_model.dart';
import '../../data/venue_data.dart';
import '../../utils/alert_utils.dart';

class VenueHeaderSlivers extends StatefulWidget {
  final String venueName;
  final String venueType;
  final String venueHours;
  final String venueAddress;
  final VoidCallback onShowOperationalHours;
  final VoidCallback onOpenMaps;

  const VenueHeaderSlivers({
    super.key,
    required this.venueName,
    required this.venueType,
    required this.venueHours,
    required this.venueAddress,
    required this.onShowOperationalHours,
    required this.onOpenMaps,
  });

  @override
  State<VenueHeaderSlivers> createState() => _VenueHeaderSliversState();
}

class _VenueHeaderSliversState extends State<VenueHeaderSlivers> {
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isBookmarked = GlobalVenueData.isFavorite(widget.venueName);
  }

  Widget _infoRow(IconData icon, String text, {String? actionText, VoidCallback? onActionTap}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _facilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // Hero Header with Venue Image
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _isBookmarked ? Colors.orange : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isBookmarked = !_isBookmarked;
                    // Find the venue data and toggle favorite
                    final venue = GlobalVenueData.venues.firstWhere(
                      (v) => v['name'] == widget.venueName,
                      orElse: () => {
                        'name': widget.venueName,
                        'type': widget.venueType,
                        'location': widget.venueAddress.split(',').last.trim(),
                        'address': widget.venueAddress,
                        'hours': widget.venueHours,
                      },
                    );
                    GlobalVenueData.toggleFavorite(venue);
                  });

                  AlertUtils.showToast(
                    context,
                    _isBookmarked 
                      ? 'Venue added to favorites' 
                      : 'Venue removed from favorites'
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Gradient background as venue image placeholder
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0E21A0),
                        Color(0xFF1A3CC8),
                        Color(0xFF0A4D8F),
                      ],
                    ),
                  ),
                ),
                // Court visual
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Icon(Icons.sports_tennis,
                          size: 64, color: Colors.white.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
                // Dark gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Venue Info Card
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Venue logo
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.sports_tennis,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.venueName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text(
                                        Review.getAverageRating(widget.venueName).toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${Review.mockReviews.where((r) => r.venueName == widget.venueName).length} reviews)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.sports_tennis,
                                          size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.venueType,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Info rows
                _infoRow(Icons.access_time, widget.venueHours,
                    actionText: 'See Other Days',
                    onActionTap: widget.onShowOperationalHours),
                const SizedBox(height: 6),
                _infoRow(Icons.location_on_outlined, widget.venueAddress,
                    actionText: 'View Maps', onActionTap: widget.onOpenMaps),
                const SizedBox(height: 12),
                // Facilities chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _facilityChip(Icons.wc, 'Restroom'),
                      const SizedBox(width: 8),
                      _facilityChip(Icons.local_parking, 'Parking'),
                      const SizedBox(width: 8),
                      _facilityChip(Icons.restaurant, 'Food and Drinks'),
                      const SizedBox(width: 8),
                      _facilityChip(Icons.mosque, 'Prayer Room'),
                      const SizedBox(width: 8),
                      _facilityChip(Icons.rule, 'Venue Rules'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // White space separator
        SliverToBoxAdapter(
          child: Container(height: 8, color: AppColors.background),
        ),
      ],
    );
  }
}
