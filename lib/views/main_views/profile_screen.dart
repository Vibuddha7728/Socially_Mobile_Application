import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore සඳහා එක් කළා
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:socially_app/models/user_model.dart';
import 'package:socially_app/services/auth/auth_service.dart';
import 'package:socially_app/services/feed/feed_service.dart';
import 'package:socially_app/services/users/user_service.dart';
import 'package:socially_app/widgets/reusable/custom_button.dart';
import 'package:socially_app/admin/services/admin_service.dart';
import 'package:socially_app/admin/screens/admin_dashboard.dart';
import 'package:socially_app/views/main_views/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserModel?> _userFuture;
  late Future<Map<String, int>> _userStatsFuture;
  bool _isLoading = true;
  bool _hasError = false;
  late String _currentUserId;
  late UserService _userService;
  late FeedService _feedService;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _userService = UserService();
    _feedService = FeedService();
    _currentUserId = AuthService().getCurrentUser()?.uid ?? '';
    _userFuture = _fetchUserDetails();
    _userStatsFuture = _fetchUserStats();
  }

  Future<UserModel?> _fetchUserDetails() async {
    try {
      final user = await _userService.getUserById(_currentUserId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (user == null) _hasError = true;
        });
      }
      return user;
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return null;
    }
  }

  Future<Map<String, int>> _fetchUserStats() async {
    try {
      final postsCount = await _feedService.getUserPostsCount(_currentUserId);
      final followersCount = await _userService.getUserFollowersCount(
        _currentUserId,
      );
      final followingCount = await _userService.getUserFollowingCount(
        _currentUserId,
      );

      return {
        'posts': postsCount,
        'followers': followersCount,
        'following': followingCount,
      };
    } catch (error) {
      return {'posts': 0, 'followers': 0, 'following': 0};
    }
  }

  void _signOut(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      GoRouter.of(context).go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          // --- Animated Notification Bell with Badge ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUserId)
                .collection('notifications')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = snapshot.hasData
                  ? snapshot.data!.docs.length
                  : 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 10,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves
                            .elasticOut, // පොඩි ගැස්සීමක් (Bounce) සහිතව මතුවීමට
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF0F0E13),
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (_isLoading)
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          if (_hasError || !snapshot.hasData) {
            return const Center(
              child: Text(
                'User not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final user = snapshot.data!;
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileImage(user.imageUrl),
                const SizedBox(height: 20),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user.jobTitle,
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 25),
                _buildStatsSection(),
                const SizedBox(height: 30),
                _buildActionButtons(user),
              ],
            ),
          );
        },
      ),
    );
  }

  // UI කොටස් පහසුව සඳහා වෙනම Method ලෙස වෙන් කළා
  Widget _buildProfileImage(String url) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10, width: 2),
      ),
      child: CircleAvatar(
        radius: 65,
        backgroundColor: Colors.grey[900],
        backgroundImage: url.isNotEmpty
            ? NetworkImage(url)
            : const AssetImage('assets/logo.png') as ImageProvider,
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<Map<String, int>>(
      future: _userStatsFuture,
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? {'posts': 0, 'followers': 0, 'following': 0};
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatColumn('Posts', stats['posts'].toString()),
            _buildStatColumn('Followers', stats['followers'].toString()),
            _buildStatColumn('Following', stats['following'].toString()),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          if (user.userId != _currentUserId)
            FutureBuilder<bool>(
              future: _userService.isFollowing(_currentUserId, user.userId),
              builder: (context, snapshot) {
                final isFollowing = snapshot.data ?? false;
                return ReusableButton(
                  onPressed: () {},
                  width: double.infinity,
                  text: isFollowing ? 'Unfollow' : 'Follow',
                );
              },
            ),
          const SizedBox(height: 10),
          FutureBuilder<bool>(
            future: _adminService.isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return ReusableButton(
                  text: 'Admin Dashboard',
                  width: double.infinity,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboard(),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 10),
          ReusableButton(
            onPressed: () => _signOut(context),
            width: double.infinity,
            text: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
