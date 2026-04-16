import 'package:flutter/material.dart';

class Review {
  final String username;
  final String venueName;
  final String courtName;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.username,
    required this.venueName,
    required this.courtName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  static List<Review> mockReviews = [
    Review(
      username: 'Salsabila',
      venueName: 'Bandung Elektrik Cigereleng Tennis Court',
      courtName: 'BEC Tennis Court Lap.A',
      rating: 5.0,
      comment: 'Tempatnya bersih banget, fasilitas mantap!',
      date: DateTime(2026, 4, 10),
    ),
    Review(
      username: 'Andi',
      venueName: 'Bandung Elektrik Cigereleng Tennis Court',
      courtName: 'BEC Tennis Court Lap.B',
      rating: 4.5,
      comment: 'Lantainya enak buat lari, ga licin.',
      date: DateTime(2026, 4, 11),
    ),
    Review(
      username: 'Budi',
      venueName: 'Bandung Elektrik Cigereleng Tennis Court',
      courtName: 'BEC Tennis Court Lap.A',
      rating: 4.0,
      comment: 'Gampang carinya, parkiran luas.',
      date: DateTime(2026, 4, 12),
    ),
  ];

  static double getAverageRating(String venueName) {
    final venueReviews = mockReviews.where((r) => r.venueName == venueName).toList();
    if (venueReviews.isEmpty) return 0.0;
    
    final total = venueReviews.fold(0.0, (sum, r) => sum + r.rating);
    return total / venueReviews.length;
  }

  static bool canUserReview(String username, String courtName) {
    return !mockReviews.any((r) => r.username == username && r.courtName == courtName);
  }
}
