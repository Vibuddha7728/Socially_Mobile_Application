import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:socially_app/models/post_model.dart'; // ඉහත Model එක මෙතැනට Import කරන්න
import 'package:socially_app/services/feed/feed_service.dart';
import 'package:socially_app/services/report_service.dart';
import 'package:socially_app/utils/constants/colors.dart';
import 'package:socially_app/utils/util_functions/mood.dart';

class PostWidget extends StatefulWidget {
  final Post post; // මෙතැන Post යනු post_model.dart හි ඇති class එකයි
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String currentUserId;

  const PostWidget({
    super.key,
    required this.post,
    required this.onEdit,
    required this.onDelete,
    required this.currentUserId,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
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

  // රිපෝර්ට් කිරීමේදී Reason එක තෝරාගැනීමට
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
            padding: EdgeInsets.all(16.0),
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
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete'),
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
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                ),
                onPressed: _likePost,
              ),
              Text(
                "${widget.post.likes} likes",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
