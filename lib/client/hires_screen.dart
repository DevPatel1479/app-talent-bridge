// import 'package:flutter/material.dart';

// class HiresPage extends StatelessWidget {
//   const HiresPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     bool isLandscape = screenSize.width > screenSize.height;

//     if (isLandscape) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.warning, color: Colors.redAccent, size: 50),
//               const SizedBox(height: 10),
//               const Text(
//                 "This screen does not support landscape mode.\nPlease switch to portrait mode.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.white, fontSize: 18),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text("My Hires", style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.grey.shade900,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(screenSize.width * 0.04),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildSectionTitle("Ongoing Hires"),
//               _buildHireList(context, 3, "Ongoing"),
//               _buildSectionTitle("Pending Requests"),
//               _buildHireList(context, 2, "Pending"),
//               _buildSectionTitle("Past Hires"),
//               _buildHireList(context, 4, "Past"),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Text(title,
//           style: const TextStyle(
//               color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
//     );
//   }

//   Widget _buildHireList(BuildContext context, int count, String type) {
//     final screenSize = MediaQuery.of(context).size;

//     return SizedBox(
//       height: screenSize.height * 0.35,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: count,
//         itemBuilder: (context, index) {
//           return _buildHireCard(context, index, type);
//         },
//       ),
//     );
//   }

//   Widget _buildHireCard(BuildContext context, int index, String type) {
//     final screenSize = MediaQuery.of(context).size;

//     return Container(
//       width: screenSize.width * 0.85,
//       margin: const EdgeInsets.only(right: 12, bottom: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade900,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: screenSize.width * 0.08,
//             backgroundColor: Colors.blueAccent,
//             child: Text(
//               "F${index + 1}",
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("Freelancer ${index + 1}",
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 4),
//                 Text("UI/UX Designer · ₹${(20 * 83).toStringAsFixed(0)}/hr",
//                     style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 14)), // Converted to INR
//                 const SizedBox(height: 4),
//                 const Text("Location: Mumbai, India",
//                     style: TextStyle(color: Colors.white54, fontSize: 12)),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.star, color: Colors.yellow, size: 16),
//                     const SizedBox(width: 4),
//                     Text("4.${index + 5} ★",
//                         style:
//                             const TextStyle(color: Colors.white, fontSize: 14)),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 if (type == "Pending")
//                   ElevatedButton(
//                     onPressed: () {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                             content: Text(
//                                 "Request Approved for Freelancer ${index + 1}")),
//                       );
//                     },
//                     style:
//                         ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                     child: const Text("Approve",
//                         style: TextStyle(color: Colors.white)),
//                   ),
//               ],
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.message, color: Colors.blueAccent),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text("Messaging Freelancer ${index + 1}...")),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.payment, color: Colors.greenAccent),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                     content: Text(
//                         "Processing Payment for Freelancer ${index + 1}...")),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
