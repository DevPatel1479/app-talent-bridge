import 'package:flutter/material.dart';
import 'package:talentbridge/screens/client_dashboard_screen.dart'
    show CarouselWidget, RecommendedFreelancersSection, ActiveProposalsSection;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header: Current Active Project.
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Icon(Icons.work_outline, color: Colors.lightBlueAccent),
                  SizedBox(width: 8),
                  Text(
                    "Current Active Project",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Carousel widget.
        const SliverToBoxAdapter(child: CarouselWidget()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        // Recommended Freelancers section.
        // const SliverToBoxAdapter(child: RecommendedFreelancersSection()),
        // const SliverToBoxAdapter(child: SizedBox(height: 24)),
        // Active Proposals section.
        const SliverToBoxAdapter(child: ActiveProposalsSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
