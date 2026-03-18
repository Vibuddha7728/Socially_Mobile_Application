import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final int age;
  final String jobTitle;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String password;
  final int followersCount;
  final int followingCount;
  final String role;
  final bool isBlocked; // අලුතින් එක් කළා (Admin Panel එක සඳහා)

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.age,
    required this.jobTitle,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.password,
    this.followersCount = 0,
    this.followingCount = 0,
    this.role = 'user',
    this.isBlocked = false, // Default එක false ලෙස ලබා දුන්නා
  });

  // Convert a User instance to a map (for saving to Firestore)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'age': age,
      'jobTitle': jobTitle,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'password': password,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'role': role,
      'isBlocked': isBlocked, // Firestore එකට save කිරීමට එක් කළා
    };
  }

  // Create a User instance from a map (for retrieving from Firestore)
  factory UserModel.fromJson(Map<String, dynamic> data) {
    return UserModel(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      age: data['age'] is int
          ? data['age']
          : int.tryParse(data['age']?.toString() ?? '0') ?? 0,
      jobTitle: data['jobTitle'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      password: data['password'] ?? '',
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      role: data['role'] ?? 'user',
      isBlocked:
          data['isBlocked'] ?? false, // Firestore එකෙන් ලබා ගැනීමට එක් කළා
    );
  }
}
