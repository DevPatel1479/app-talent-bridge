
import 'package:flutter/material.dart';

class Gig {
  final String title;
  final String clientName;
  final String imageUrl;
  final double rating;
  final double minPrice;
  final double maxPrice;
  final VoidCallback onViewProposal;

  Gig({
    required this.title,
    required this.clientName,
    required this.imageUrl,
    required this.rating,
    required this.minPrice,
    required this.maxPrice,
    required this.onViewProposal,
  });
}
