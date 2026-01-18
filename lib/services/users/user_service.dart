// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socially_app/models/user_model.dart';

class UserService {
  // Collection references
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // 1. Save User - දැන් මෙතනදී ආයෙත් Auth create කරන්නේ නැහැ, කෙලින්ම දත්ත save කරනවා විතරයි
  Future<void> saveUser(UserModel user) async {
    try {
      // RegisterScreen එකෙන් ලැබෙන user.userId එක පාවිච්චි කරනවා
      if (user.userId.isNotEmpty) {
        final userRef = _usersCollection.doc(user.userId);

        // User model එක Map එකක් කරගෙන අවශ්‍ය fields එකතු කරනවා
        final userMap = user.toJson();

        // Admin system එක වැඩ කිරීමට මේ fields අනිවාර්යයි
        userMap['role'] = userMap['role'] ?? 'user';
        userMap['followersCount'] = userMap['followersCount'] ?? 0;
        userMap['followingCount'] = userMap['followingCount'] ?? 0;

        await userRef.set(userMap);
        print('User saved successfully to Firestore: ${user.userId}');
      } else {
        print('Error: User ID is empty. Cannot save to Firestore.');
      }
    } catch (error) {
      print('Error saving user to Firestore: $error');
      rethrow;
    }
  }

  // 2. Get user details by id
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (error) {
      print('Error getting user: $error');
    }
    return null;
  }

  // 3. Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (error) {
      print('Error getting users: $error');
      return [];
    }
  }

  // 4. Follow User
  Future<void> followUser(String currentUserId, String userToFollowId) async {
    try {
      // Add to followers sub-collection
      await _usersCollection
          .doc(userToFollowId)
          .collection('followers')
          .doc(currentUserId)
          .set({'followedAt': Timestamp.now()});

      // Update follower count safely using FieldValue
      await _usersCollection.doc(userToFollowId).update({
        'followersCount': FieldValue.increment(1),
      });

      // Update following count for current user
      await _usersCollection.doc(currentUserId).update({
        'followingCount': FieldValue.increment(1),
      });

      print('User followed successfully');
    } catch (error) {
      print('Error following user: $error');
    }
  }

  // 5. Unfollow User
  Future<void> unfollowUser(
    String currentUserId,
    String userToUnfollowId,
  ) async {
    try {
      await _usersCollection
          .doc(userToUnfollowId)
          .collection('followers')
          .doc(currentUserId)
          .delete();

      await _usersCollection.doc(userToUnfollowId).update({
        'followersCount': FieldValue.increment(-1),
      });

      await _usersCollection.doc(currentUserId).update({
        'followingCount': FieldValue.increment(-1),
      });

      print('User unfollowed successfully');
    } catch (error) {
      print('Error unfollowing user: $error');
    }
  }

  // 6. Check Follow Status
  Future<bool> isFollowing(String currentUserId, String userToCheckId) async {
    try {
      final docSnapshot = await _usersCollection
          .doc(userToCheckId)
          .collection('followers')
          .doc(currentUserId)
          .get();
      return docSnapshot.exists;
    } catch (error) {
      return false;
    }
  }

  // 7. Get Counts (Simplified)
  Future<int> getUserFollowersCount(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    return (doc.data() as Map<String, dynamic>?)?['followersCount'] ?? 0;
  }

  Future<int> getUserFollowingCount(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    return (doc.data() as Map<String, dynamic>?)?['followingCount'] ?? 0;
  }
}
