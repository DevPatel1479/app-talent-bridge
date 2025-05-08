import 'package:flutter/material.dart';

import 'Glowing_widget.dart';

Widget buildProjectCard(
    String projectTitle, double projectStatusValue, void Function()? callback) {
  return GlowingContainer(
    borderRadius: 16,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.code, color: Colors.blueAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  projectTitle, // Dynamically set project title
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis, // Prevent overflow issues
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: projectStatusValue, // Use dynamic progress value
                backgroundColor: Colors.black38,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF00C9A7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(projectStatusValue * 100).toInt()}% Completed', // Show dynamic progress percentage
                    style: const TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: callback,
                    child: const Text(
                      'View Details',
                      style: TextStyle(color: Color.fromARGB(255, 40, 203, 179)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
