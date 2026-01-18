import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Report එකක් Firestore එකට එකතු කිරීම සහ Auto-Delete පරීක්ෂාව
  Future<void> submitReport({
    required String targetId, // Post ID එක
    required String targetType, // 'post' හෝ 'reel'
    required String reason, // හේතුව
    required String ownerId, // Post එක අයිති කෙනාගේ ID එක
    required String ownerName, // Admin Dashboard එකේ පෙන්වීමට නම
  }) async {
    try {
      final String reporterId =
          FirebaseAuth.instance.currentUser?.uid ?? "unknown";

      // 1. "reports" collection එකට රිපෝට් එකේ විස්තර ඇතුළත් කිරීම
      await _db.collection('reports').add({
        'reporterId': reporterId,
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason,
        'reportedUserId': ownerId,
        'reportedUserName': ownerName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // 2. Auto-Delete Logic එක ක්‍රියාත්මක කිරීම (targetType එක 'post' නම් පමණක්)
      if (targetType == 'post') {
        DocumentReference postRef = _db.collection('feed').doc(targetId);

        await _db.runTransaction((transaction) async {
          DocumentSnapshot postSnap = await transaction.get(postRef);

          if (postSnap.exists) {
            Map<String, dynamic> data = postSnap.data() as Map<String, dynamic>;
            int currentReports = data['reportCount'] ?? 0;
            int newCount = currentReports + 1;

            if (newCount >= 10) {
              // රිපෝට් 10 හෝ ඊට වැඩි නම් පෝස්ට් එක මකා දමන්න
              transaction.delete(postRef);
              print(
                "Post $targetId deleted automatically due to high reports.",
              );
            } else {
              // රිපෝට් 10ට අඩු නම් count එක update කරන්න
              transaction.update(postRef, {'reportCount': newCount});
            }
          }
        });
      }
    } catch (e) {
      print("Error submitting report: $e");
    }
  }
}
