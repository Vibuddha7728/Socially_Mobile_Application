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
      // FeedService එක හරහා පෝස්ට් එක මැකීම
      await FeedService().deletePost(postId: postId, postUrl: postUrl);

      // Async gap එකකින් පසු context එක තවමත් පවතීදැයි පරීක්ෂා කිරීම (Best Practice)
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

    return Scaffold(
      backgroundColor: Colors.black, // හෝ ඔබේ theme එකේ පසුබිම් වර්ණය
      body: StreamBuilder<List<Post>>(
        stream: FeedService().getPostsStream(),
        builder: (context, snapshot) {
          // දත්ත ලැබෙන තෙක් Loading indicator එකක් පෙන්වීම
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // දෝෂයක් ඇත්නම් එය පෙන්වීම
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          // දත්ත නොමැති නම්
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No posts available.',
                style: TextStyle(color: Colors.white54),
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
                  PostWidget(
                    post: post,
                    currentUserId: currentUserId,
                    onEdit: () {
                      // Edit කිරීමට අවශ්‍ය logic එක පසුව එක් කළ හැක
                    },
                    onDelete: () async {
                      // මැකීමට පෙර තහවුරු කිරීමක් (Confirmation) ලබා ගැනීම සුදුසුයි
                      await _deletePost(post.postId, post.postUrl, context);
                    },
                  ),
                  Divider(
                    color: mainWhiteColor.withOpacity(0.1),
                    thickness: 0.5,
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
