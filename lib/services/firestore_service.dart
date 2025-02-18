import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> postJob(String title, String description, String userId) async {
    await _db.collection('jobs').add({
      'title': title,
      'description': description,
      'postedBy': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
