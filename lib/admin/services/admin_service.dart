import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SMS API Configurations
  static const String _smsApiKey =
      '413|0kkQbVo9Sw7EmjaIKeejhRDHdtHImBOfesPIa10M';
  static const String _smsApiUrl =
      'https://dashboard.smsapi.lk/api/v3/sms/send';

  // 1. Admin ද කියලා පරීක්ෂා කිරීම
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      final userDoc = await _db.collection('users').doc(user.uid).get();
      return userDoc.data()?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // 2. Dashboard Stats (Real-time)
  Stream<Map<String, int>> getAppStats() {
    return CombineLatestStream.combine4(
      _db.collection('users').snapshots(),
      _db.collection('feed').snapshots(),
      _db.collection('reels').snapshots(),
      _db.collection('reports').snapshots(),
      (users, feed, reels, reports) {
        return {
          'users': users.docs.length,
          'posts': feed.docs.length,
          'reels': reels.docs.length,
          'reports': reports.docs.length,
        };
      },
    ).onErrorReturn({'users': 0, 'posts': 0, 'reels': 0, 'reports': 0});
  }

  // 3. Analytics
  Stream<Map<String, dynamic>> getAnalyticsStats() {
    return _db.collection('users').snapshots().map((userSnap) {
      int totalUsers = userSnap.docs.length;
      int age18_24 = 0, age25_34 = 0, age35_50 = 0, age50Plus = 0;
      Map<String, int> weeklyGrowth = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };

      for (var doc in userSnap.docs) {
        final data = doc.data();
        int age = int.tryParse(data['age']?.toString() ?? '0') ?? 0;
        if (age >= 18 && age <= 24)
          age18_24++;
        else if (age >= 25 && age <= 34)
          age25_34++;
        else if (age >= 35 && age <= 50)
          age35_50++;
        else if (age > 50)
          age50Plus++;

        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          Timestamp ts = data['createdAt'];
          String dayName = DateFormat('E').format(ts.toDate());
          if (weeklyGrowth.containsKey(dayName)) {
            weeklyGrowth[dayName] = weeklyGrowth[dayName]! + 1;
          }
        }
      }
      return {
        'dau': totalUsers,
        'engagement_rate': "68%",
        'age_demographics': {
          '18-24': age18_24,
          '25-34': age25_34,
          '35-50': age35_50,
          '50+': age50Plus,
        },
        'weekly_growth': weeklyGrowth,
      };
    });
  }

  // 4. User Management
  Stream<QuerySnapshot> getAllUsers() =>
      _db.collection('users').orderBy('name').snapshots();

  // 5. User Block/Unblock
  Future<void> toggleUserBlock(String userId, bool blockStatus) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isBlocked': blockStatus,
        'blockedAt': blockStatus ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  // 6. Block Status Check
  Stream<bool> isUserBlocked(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      return (doc.data() as Map<String, dynamic>?)?['isBlocked'] ?? false;
    });
  }

  // 7. Delete Post
  Future<void> deletePost(String postId) async {
    try {
      await _db.collection('feed').doc(postId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // 8. Reports
  Stream<QuerySnapshot> getAllReports() => _db
      .collection('reports')
      .orderBy('timestamp', descending: true)
      .snapshots();

  // 9. Dismiss Report
  Future<void> dismissReport(String reportId) async {
    try {
      await _db.collection('reports').doc(reportId).delete();
    } catch (e) {
      print("Error: $e");
    }
  }

  // 10. Broadcast පණිවුඩය (Inbox)
  Future<void> sendBroadcastToInboxes({
    required String title,
    required String message,
  }) async {
    try {
      QuerySnapshot usersSnapshot = await _db.collection('users').get();
      WriteBatch batch = _db.batch();
      for (var userDoc in usersSnapshot.docs) {
        DocumentReference ref = _db
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();
        batch.set(ref, {
          'title': 'Socially Admin',
          'shortBody': title,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
      await batch.commit();
    } catch (e) {
      print("Broadcast Error: $e");
      rethrow;
    }
  }

  // Phone Formatting
  String _formatPhone(String phone) {
    phone = phone
        .trim()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('+', '');
    if (phone.startsWith('94')) return phone;
    if (phone.startsWith('0')) return '94${phone.substring(1)}';
    return '94$phone';
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^94\d{9}$').hasMatch(phone);
  }

  // 11. Single SMS Core Function
  Future<void> sendSms({required String phone, required String message}) async {
    try {
      final String formattedPhone = _formatPhone(phone);
      final response = await http.post(
        Uri.parse(_smsApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_smsApiKey',
        },
        body: jsonEncode({
          'recipient': formattedPhone,
          'sender_id': 'NotifyDEMO',
          'type': 'plain',
          'message': message,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("SMS failed: ${response.body}");
      }
    } catch (e) {
      print("SMS Error: $e");
      rethrow;
    }
  }

  // 12. Single User කෙනෙකුට SMS යැවීම (Firestore එකෙන් number එක අරන්)
  Future<void> sendSmsToSingleUser({
    required String userId,
    required String message,
  }) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception("User not found");

      final String phone = (userDoc.data()?['phone'] ?? '').toString();
      if (phone.isEmpty) throw Exception("User phone number not found");

      await sendSms(phone: phone, message: message);
    } catch (e) {
      print("Single User SMS Error: $e");
      rethrow;
    }
  }

  // 13. සියලුම Users ලාට SMS යැවීම
  Future<void> sendSmsToAllUsers({required String message}) async {
    try {
      final usersSnapshot = await _db.collection('users').get();
      List<String> validRecipients = [];

      for (var userDoc in usersSnapshot.docs) {
        final data = userDoc.data();
        final String rawPhone = (data['phone'] ?? '').toString();
        if (rawPhone.isNotEmpty) {
          final String formatted = _formatPhone(rawPhone);
          if (_isValidPhone(formatted)) {
            validRecipients.add(formatted);
          }
        }
      }

      if (validRecipients.isEmpty)
        throw Exception("No valid phone numbers found");

      final response = await http.post(
        Uri.parse(_smsApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_smsApiKey',
        },
        body: jsonEncode({
          'recipient': validRecipients.join(','),
          'sender_id': 'SMSAPI Demo',
          'type': 'plain',
          'message': message,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Bulk SMS failed: ${response.body}");
      }
    } catch (e) {
      print("Bulk SMS Error: $e");
      rethrow;
    }
  }
}
