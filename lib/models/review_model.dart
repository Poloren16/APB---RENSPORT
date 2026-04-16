import 'package:flutter/material.dart';

class Review {
  final String username;
  final String venueName;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.username,
    required this.venueName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  static List<Review> mockReviews = [];

  static double getAverageRating(String venueName) {
    final venueReviews = mockReviews.where((r) => r.venueName == venueName).toList();
    if (venueReviews.isEmpty) return 0.0;
    
    final total = venueReviews.fold(0.0, (sum, r) => sum + r.rating);
    return total / venueReviews.length;
  }

  static bool hasUserReviewed(String username, String venueName) {
    return mockReviews.any((r) => r.username == username && r.venueName == venueName);
  }

  static Review? findUserReview(String username, String venueName) {
    try {
      return mockReviews.firstWhere((r) => r.username == username && r.venueName == venueName);
    } catch (_) {
      return null;
    }
  }
}
