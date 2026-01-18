// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth එක් කළා
import 'package:socially_app/models/reel_model.dart';
import 'package:socially_app/services/reels/reel_storage.dart';

class ReelService {
  final CollectionReference _reelsCollection = FirebaseFirestore.instance
      .collection('reels');

  // FirebaseAuth instance එක ලබාගැනීම
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- 1. Fetch Reels Stream ---
  Stream<QuerySnapshot> getReels() {
    return _reelsCollection
        .orderBy('datePublished', descending: true)
        .snapshots();
  }

  // --- 2. Save a new Reel ---
  Future<void> saveReel(Map<String, dynamic> reelDetails) async {
    try {
      // දැනට Log වී සිටින User ලබාගැනීම
      User? currentUser = _auth.currentUser;

      final reel = Reel(
        caption: reelDetails['caption'],
        videoUrl: reelDetails['videoUrl'],
        // ප්ලේස්හෝල්ඩර් වෙනුවට නියම User ID සහ Username ඇතුළත් කිරීම
        userId: currentUser?.uid ?? 'unknown-uid',
        username: currentUser?.displayName ?? 'Anonymous',
        reelId: '',
        datePublished: DateTime.now(),
      );

      final docRef = await _reelsCollection.add(reel.toJson());
      await docRef.update({'reelId': docRef.id});
    } catch (e) {
      print("Error saving reel: $e");
    }
  }

  // --- 3. Update Reel Caption ---
  Future<void> updateReel(Reel reel, String newCaption) async {
    try {
      await _reelsCollection.doc(reel.reelId).update({'caption': newCaption});
      print("Reel updated successfully!");
    } catch (e) {
      print("Error updating reel: $e");
      rethrow;
    }
  }

  // --- 4. Delete Reel ---
  Future<void> deleteReel(Reel reel) async {
    try {
      await _reelsCollection.doc(reel.reelId).delete();
      await ReelStorageService().deleteVideo(videoUrl: reel.videoUrl);
      print("Reel deleted successfully!");
    } catch (e) {
      print("Error deleting reel: $e");
    }
  }

  // --- 5. Post a Comment ---
  // මෙහිදී 'Guest User' වෙනුවට Logged-in User ගේ තොරතුරු භාවිතා වේ
  Future<void> postComment(String reelId, String commentText) async {
    try {
      User? currentUser = _auth.currentUser;

      if (commentText.trim().isNotEmpty) {
        await _reelsCollection.doc(reelId).collection('comments').add({
          'text': commentText.trim(),
          'datePublished': DateTime.now(),
          // Firebase Auth එකෙන් නම ලබාගන්නවා, නැතිනම් 'User' ලෙස දමනවා
          'username': currentUser?.displayName ?? 'User',
          'profilePic': currentUser?.photoURL ?? '',
          'uid': currentUser?.uid,
        });
        print("Comment added to Firestore by ${currentUser?.displayName}!");
      }
    } catch (e) {
      print("Error posting comment: $e");
    }
  }

  // --- 6. Get Comments Stream ---
  Stream<QuerySnapshot> getComments(String reelId) {
    return _reelsCollection
        .doc(reelId)
        .collection('comments')
        .orderBy('datePublished', descending: true)
        .snapshots();
  }
}
