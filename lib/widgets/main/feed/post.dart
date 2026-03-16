import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:socially_app/models/post_model.dart';
import 'package:socially_app/services/feed/feed_service.dart';
import 'package:socially_app/services/report_service.dart';
import 'package:socially_app/utils/constants/colors.dart';
import 'package:socially_app/utils/util_functions/mood.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostWidget extends StatefulWidget {
  final Post post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onComment;
  final String currentUserId;

  const PostWidget({
    super.key,
    required this.post,
    required this.onEdit,
    required this.onDelete,
    required this.onComment,
    required this.currentUserId,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool _isLiked = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkIfLiked() async {
    final hasLiked = await FeedService().hasUserLikedPost(
      postId: widget.post.postId,
      userId: widget.currentUserId,
    );
    if (mounted) setState(() => _isLiked = hasLiked);
  }

  void _likePost() async {
    try {
      if (_isLiked) {
        await FeedService().unlikePost(
          postId: widget.post.postId,
          userId: widget.currentUserId,
        );
        setState(() => _isLiked = false);
      } else {
        await FeedService().likePost(
          postId: widget.post.postId,
          userId: widget.currentUserId,
        );
        setState(() => _isLiked = true);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _sharePost() {
    final String textToShare =
        "${widget.post.postCaption}\n\nLink: ${widget.post.postUrl}";
    if (widget.post.postUrl.isNotEmpty) {
      Share.share(textToShare, subject: 'Check out this post on Socially!');
    } else {
      Share.share(widget.post.postCaption);
    }
  }

  // ✅ Comment UI (Bottom Sheet)
  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: webBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Comments",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Divider(color: Colors.white12),

            // Real-time Comments List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FeedService().getCommentsStream(widget.post.postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Center(
                      child: Text(
                        "No comments yet.",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var data =
                          snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            data['profilePic'] ??
                                'https://i.stack.imgur.com/l60Hf.png',
                          ),
                        ),
                        title: Text(
                          data['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          data['text'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Text(
                          DateFormat('HH:mm').format(
                            (data['datePublished'] as Timestamp).toDate(),
                          ),
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Input field
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: mainPurpleColor),
                    onPressed: () async {
                      if (_commentController.text.isNotEmpty) {
                        await FeedService().postComment(
                          postId: widget.post.postId,
                          text: _commentController.text,
                          uid: widget.currentUserId,
                          name: widget
                              .post
                              .username, // සාමාන්‍යයෙන් මෙතැනට ගත යුත්තේ log වී ඇති user ගේ නමයි
                          profilePic: widget
                              .post
                              .profImage, // log වී ඇති user ගේ pic එක
                        );
                        _commentController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showReportOptions() {
    final List<String> reasons = [
      "Spam",
      "Inappropriate Content",
      "Harassment",
      "Hate Speech",
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: webBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Select Reason",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...reasons.map(
            (r) => ListTile(
              title: Text(r, style: const TextStyle(color: Colors.white70)),
              onTap: () async {
                Navigator.pop(context);
                await ReportService().submitReport(
                  targetId: widget.post.postId,
                  targetType: 'post',
                  reason: r,
                  ownerId: widget.post.userId,
                  ownerName: widget.post.username,
                );
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted.')),
                  );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showOptionsDialog() {
    final bool isOwner = widget.post.userId == widget.currentUserId;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: webBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text(
                'Copy Link',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.post.postUrl));
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Link copied!')));
              },
            ),
            if (!isOwner)
              ListTile(
                leading: const Icon(
                  Icons.report_gmailerrorred,
                  color: Colors.orange,
                ),
                title: const Text(
                  'Report Post',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportOptions();
                },
              ),
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Edit',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(widget.post.datePublished);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: webBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(
                  widget.post.profImage.isEmpty
                      ? 'https://i.stack.imgur.com/l60Hf.png'
                      : widget.post.profImage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: _showOptionsDialog,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Feeling ${widget.post.mood.name} ${widget.post.mood.emoji}",
            style: const TextStyle(color: mainPurpleColor),
          ),
          const SizedBox(height: 8),
          Text(
            widget.post.postCaption,
            style: const TextStyle(color: Colors.white),
          ),
          if (widget.post.postUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(widget.post.postUrl),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: "${widget.post.likes}",
                  color: _isLiked ? Colors.red : Colors.white70,
                  onTap: _likePost,
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: "Comment",
                  color: Colors.white70,
                  onTap: _showCommentSheet,
                ), // ✅ මෙතැනදී Sheet එක පෙන්වයි
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: "Share",
                  color: Colors.white70,
                  onTap: _sharePost,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
