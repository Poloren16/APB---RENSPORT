import 'package:flutter/material.dart';
import 'dart:io';
import '../../theme/app_colors.dart';
import '../../models/review_model.dart';
import '../../data/venue_data.dart';
import '../../utils/alert_utils.dart';
import '../../pages/chat_detail_page.dart';

class VenueHeaderSlivers extends StatefulWidget {
  final String username;
  final String venueName;
  final String venueType;
  final String venueHours;
  final String venueAddress;
  final VoidCallback onShowOperationalHours;
  final VoidCallback onOpenMaps;

  const VenueHeaderSlivers({
    super.key,
    required this.username,
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
  PageController? _headerPageController;
  int _currentHeaderPage = 0;

  @override
  void initState() {
    super.initState();
    _isBookmarked = GlobalVenueData.isFavorite(widget.venueName);
    _headerPageController = PageController();
  }

  @override
  void dispose() {
    _headerPageController?.dispose();
    super.dispose();
  }

  IconData _getSportIcon(String type) {
    final cleanType = type.toLowerCase().trim();
    if (cleanType.contains('futsal') || cleanType.contains('sepak') || cleanType.contains('bola') || cleanType.contains('soccer') || cleanType.contains('mini')) {
      return Icons.sports_soccer;
    } else if (cleanType.contains('badminton') || cleanType.contains('bulu') || cleanType.contains('tangkis') || cleanType.contains('tennis') || cleanType.contains('tenis')) {
      return Icons.sports_tennis;
    } else if (cleanType.contains('basket') || cleanType.contains('ball')) {
      return Icons.sports_basketball;
    } else if (cleanType.contains('voli') || cleanType.contains('volleyball')) {
      return Icons.sports_volleyball;
    }
    return Icons.sports_soccer; // default
  }

  Widget _infoRow(IconData icon, String text,
      {String? actionText, VoidCallback? onActionTap}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                          : 'Venue removed from favorites');
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon:
                    const Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChatDetailPage(
                                username: widget.username,
                                venueName: widget.venueName,
                              )));
                },
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Builder(builder: (context) {
              _headerPageController ??= PageController();
              final venueMatch = GlobalVenueData.venues.where((v) => v['name'] == widget.venueName);
              final List<String> imageList = [];
              if (venueMatch.isNotEmpty) {
                final v = venueMatch.first;
                if (v['imagePaths'] is List) {
                  imageList.addAll(List<String>.from((v['imagePaths'] as List).map((e) => e.toString())));
                } else if (v['images'] is List) {
                  imageList.addAll(List<String>.from((v['images'] as List).map((e) => e.toString())));
                }
              }
              // If imageList is empty but main image exists, add it
              if (imageList.isEmpty && venueMatch.isNotEmpty) {
                final mainImg = venueMatch.first['image']?.toString() ?? '';
                if (mainImg.isNotEmpty) {
                  imageList.add(mainImg);
                }
              }

              Widget buildImageWidget(String path) {
                if (path.isEmpty) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFF0E21A0), Color(0xFF1A3CC8), Color(0xFF0A4D8F)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          Icon(_getSportIcon(widget.venueType), size: 64, color: Colors.white.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  );
                }
                if (path.startsWith('http://') || path.startsWith('https://')) {
                  return Image.network(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Color(0xFF0E21A0), Color(0xFF1A3CC8), Color(0xFF0A4D8F)],
                        ),
                      ),
                      child: Center(
                        child: Icon(_getSportIcon(widget.venueType), size: 64, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                  );
                } else {
                  return Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Color(0xFF0E21A0), Color(0xFF1A3CC8), Color(0xFF0A4D8F)],
                        ),
                      ),
                      child: Center(
                        child: Icon(_getSportIcon(widget.venueType), size: 64, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                  );
                }
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (imageList.isEmpty)
                    buildImageWidget('')
                  else
                    PageView.builder(
                      controller: _headerPageController,
                      itemCount: imageList.length,
                      physics: imageList.length <= 1
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentHeaderPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return buildImageWidget(imageList[index]);
                      },
                    ),
                  // Dark gradient overlay at bottom
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Pill page indicator
                  if (imageList.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentHeaderPage + 1}/${imageList.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
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
                    // Venue logo / Avatar
                    Builder(
                      builder: (context) {
                        final venueMatch = GlobalVenueData.venues.where((v) => v['name'] == widget.venueName);
                        final mainImage = venueMatch.isNotEmpty ? (venueMatch.first['image']?.toString() ?? '') : '';

                        Widget buildAvatarFallback() {
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Icon(_getSportIcon(widget.venueType),
                                color: AppColors.primary, size: 24),
                          );
                        }

                        if (mainImage.isEmpty) {
                          return buildAvatarFallback();
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: mainImage.startsWith('http')
                                ? Image.network(
                                    mainImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => buildAvatarFallback(),
                                  )
                                : Image.file(
                                    File(mainImage),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => buildAvatarFallback(),
                                  ),
                          ),
                        );
                      },
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
                                  const Icon(Icons.star_rounded,
                                      size: 16, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    Review.getAverageRating(widget.venueName)
                                        .toStringAsFixed(1),
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
                                  Icon(_getSportIcon(widget.venueType),
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
                    actionText: 'Lihat Hari Lain',
                    onActionTap: widget.onShowOperationalHours),
                const SizedBox(height: 6),
                _infoRow(Icons.location_on_outlined, widget.venueAddress,
                    actionText: 'Lihat Peta', onActionTap: widget.onOpenMaps),
                const SizedBox(height: 12),
                // Facilities chips — dari data court nyata
                Builder(builder: (context) {
                  final venueMatch = GlobalVenueData.venues.where((v) => v['name'] == widget.venueName);
                  final List<String> allFacilities = [];
                  if (venueMatch.isNotEmpty) {
                    final courts = venueMatch.first['courts'] as List<dynamic>? ?? [];
                    for (final c in courts) {
                      final facs = c['facilities'] as List<dynamic>?
                          ?? (c['facility'] != null ? [c['facility']] : []);
                      for (final f in facs) {
                        final fs = f.toString();
                        if (!allFacilities.contains(fs)) allFacilities.add(fs);
                      }
                    }
                  }
                  // Fallback minimal
                  if (allFacilities.isEmpty) return const SizedBox.shrink();

                  final Map<String, IconData> facilityIcons = {
                    'Kamar Mandi': Icons.wc,
                    'Parkiran': Icons.local_parking,
                    'Kantin': Icons.restaurant,
                    'Mushola': Icons.mosque,
                    'Locker Room': Icons.lock_outline,
                    'Toilet': Icons.wc,
                    'Parkir': Icons.local_parking,
                    'Makanan & Minuman': Icons.restaurant,
                    'Prayer Room': Icons.mosque,
                  };

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: allFacilities.asMap().entries.map((e) => Padding(
                        padding: EdgeInsets.only(right: e.key < allFacilities.length - 1 ? 8 : 0),
                        child: _facilityChip(
                          facilityIcons[e.value] ?? Icons.check_circle_outline,
                          e.value,
                        ),
                      )).toList(),
                    ),
                  );
                }),
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
