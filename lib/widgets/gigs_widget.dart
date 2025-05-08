import 'package:flutter/material.dart';
import 'package:talentbridge/model/GigModel.dart';

Widget buildGigsList({
  required List<Gig> gigs,
  bool shrinkWrap = true,
  ScrollPhysics? physics = const NeverScrollableScrollPhysics(),
}) {
  return ListView.separated(
    shrinkWrap: shrinkWrap,
    physics: physics,
    itemCount: gigs.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      final gig = gigs[index];
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                gig.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gig.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          gig.clientName,
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        gig.rating.toString(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bottom row with price range and button.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '\$${gig.minPrice} - \$${gig.maxPrice}',
                          style: const TextStyle(
                            color: Color(0xFF00C9A7),
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: gig.onViewProposal,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00C9A7)),
                        ),
                        child: const Text(
                          'View Proposal',
                          style: TextStyle(color: Color(0xFF00C9A7)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
