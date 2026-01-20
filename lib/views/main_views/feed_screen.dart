import 'package:flutter/material.dart';
import 'package:socially_app/models/post_model.dart';
import 'package:socially_app/services/auth/auth_service.dart';
import 'package:socially_app/services/feed/feed_service.dart';
import 'package:socially_app/utils/constants/colors.dart';
import 'package:socially_app/widgets/main/feed/post.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  // පෝස්ට් එක මැකීමේ ක්‍රියාවලිය
  Future<void> _deletePost(
    String postId,
    String postUrl,
    BuildContext context,
  ) async {
    try {
      await FeedService().deletePost(postId: postId, postUrl: postUrl);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting post: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error deleting post'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // වත්මන් පරිශීලකයාගේ ID එක ලබා ගැනීම
    final String currentUserId = AuthService().getCurrentUser()?.uid ?? "";

    // 🌓 තේමාව Dark ද නැද්ද යන්න පරීක්ෂා කිරීම
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 🔹 පසුබිම් වර්ණය Theme එකට අනුව ස්වයංක්‍රීයව වෙනස් වේ
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<Post>>(
        stream: FeedService().getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No posts available.',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            );
          }

          final posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final post = posts[index];

              return Column(
                children: [
                  // ✅ Post එකේ වර්ණ පාලනය මෙතනින් සිදු වේ
                  Theme(
                    data: Theme.of(context).copyWith(
                      // Light mode එකේදී අකුරු සහ icons කළු පැහැයට හැරේ
                      textTheme: Theme.of(context).textTheme.apply(
                        bodyColor: isDark ? Colors.white : Colors.black,
                        displayColor: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    child: PostWidget(
                      post: post,
                      currentUserId: currentUserId,
                      onEdit: () {
                        // Edit logic
                      },
                      onDelete: () async {
                        await _deletePost(post.postId, post.postUrl, context);
                      },
                    ),
                  ),
                  Divider(
                    // 🌓 Divider එකේ වර්ණය ලස්සනට පෙනෙන ලෙස සැකසීම
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    thickness: 1,
                    height: 1,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
