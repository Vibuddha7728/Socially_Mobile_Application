import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // 🔹 එකතු කරන ලදී
import 'package:socially_app/models/user_model.dart';
import 'package:socially_app/services/auth/auth_service.dart';
import 'package:socially_app/services/feed/feed_service.dart';
import 'package:socially_app/services/users/user_service.dart';
import 'package:socially_app/widgets/reusable/custom_button.dart';
import 'package:socially_app/admin/services/admin_service.dart';
import 'package:socially_app/admin/screens/admin_dashboard.dart';
import 'package:socially_app/views/main_views/notifications_screen.dart';
import 'package:socially_app/providers/theme_provider.dart'; // 🔹 එකතු කරන ලදී

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
    // 🔹 ThemeProvider එක ලබා ගැනීම
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      // 🌓 තේමාව අනුව පසුබිම් වර්ණය වෙනස් වේ
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          // Notification Bell
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
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: isDark ? Colors.white : Colors.black,
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
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF0F0E13)
                                      : Colors.white,
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

          // 🌓 Theme Switch Button (Settings Icon එක වෙනුවට හෝ එය සමඟ)
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (_isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.white : Colors.orange,
              ),
            );
          }
          if (_hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'User not found',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            );
          }

          final user = snapshot.data!;
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileImage(user.imageUrl, isDark),
                const SizedBox(height: 20),
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  user.jobTitle,
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 25),
                _buildStatsSection(isDark),
                const SizedBox(height: 30),
                _buildActionButtons(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileImage(String url, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 65,
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
        backgroundImage: url.isNotEmpty
            ? NetworkImage(url)
            : const AssetImage('assets/logo.png') as ImageProvider,
      ),
    );
  }

  Widget _buildStatsSection(bool isDark) {
    return FutureBuilder<Map<String, int>>(
      future: _userStatsFuture,
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? {'posts': 0, 'followers': 0, 'following': 0};
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatColumn('Posts', stats['posts'].toString(), isDark),
            _buildStatColumn(
              'Followers',
              stats['followers'].toString(),
              isDark,
            ),
            _buildStatColumn(
              'Following',
              stats['following'].toString(),
              isDark,
            ),
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

  Widget _buildStatColumn(String title, String value, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
