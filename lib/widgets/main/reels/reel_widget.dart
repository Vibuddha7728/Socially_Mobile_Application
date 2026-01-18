import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:share_plus/share_plus.dart';
import 'package:socially_app/models/reel_model.dart';
import 'package:socially_app/services/reels/reel_service.dart';

class ReelWidget extends StatefulWidget {
  final Reel reel;

  const ReelWidget({required this.reel, Key? key}) : super(key: key);

  @override
  State<ReelWidget> createState() => _ReelWidgetState();
}

class _ReelWidgetState extends State<ReelWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showIcon = false;
  bool _isLiked = false;
  IconData _overlayIcon = Icons.play_arrow_rounded;
  late String _displayCaption;

  final TextEditingController _commentController = TextEditingController();
  final ReelService _reelService = ReelService(); // Service instance එක

  @override
  void initState() {
    super.initState();
    _displayCaption = widget.reel.caption;
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.network(widget.reel.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _controller.setLooping(true);
          });
        }
      });
  }

  // --- Comment Section Logic ---
  void _addComment() async {
    String commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      // ReelService එකේ ඇති function එක ඇමතීම
      await _reelService.postComment(widget.reel.reelId, commentText);

      _commentController.clear();

      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Comment posted!"),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "Comments",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // --- Real-time Comments List ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _reelService.getComments(widget.reel.reelId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No comments yet.",
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var ds = snapshot.data!.docs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.pinkAccent.withOpacity(
                                0.2,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white70,
                              ),
                            ),
                            title: Text(
                              ds['username'] ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              ds['text'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // --- Input Box Area ---
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                    top: 10,
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
                            fillColor: Colors.white10,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _addComment,
                        child: const CircleAvatar(
                          backgroundColor: Colors.pinkAccent,
                          radius: 24,
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- අනෙකුත් Functionalities (Play/Pause, Like, Edit, Delete) ---

  void _onVideoTap() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _overlayIcon = Icons.pause_rounded;
      } else {
        _controller.play();
        _overlayIcon = Icons.play_arrow_rounded;
      }
      _showIcon = true;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showIcon = false);
    });
  }

  void _toggleLike() {
    setState(() => _isLiked = !_isLiked);
  }

  void _editReel() {
    TextEditingController _editController = TextEditingController(
      text: _displayCaption,
    );
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Edit Caption",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _editController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 3,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.black26,
                                hintText: "Update your caption...",
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pinkAccent
                                        .withOpacity(0.8),
                                  ),
                                  onPressed: () async {
                                    String newText = _editController.text
                                        .trim();
                                    setState(() => _displayCaption = newText);
                                    await _reelService.updateReel(
                                      widget.reel,
                                      newText,
                                    );
                                    if (mounted) Navigator.pop(context);
                                  },
                                  child: const Text("Save Changes"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _shareReel() {
    Share.share('Check out this reel: ${widget.reel.videoUrl}');
  }

  void _deleteReel(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Delete Reel?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this reel?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) await _reelService.deleteReel(widget.reel);
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.reel.videoUrl),
      onVisibilityChanged: (visibilityInfo) {
        if (!mounted) return;
        if (_isInitialized) {
          if (visibilityInfo.visibleFraction * 100 > 80)
            _controller.play();
          else
            _controller.pause();
        }
      },
      child: GestureDetector(
        onTap: _onVideoTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: _isInitialized
                    ? SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Colors.pinkAccent,
                        ),
                      ),
              ),

              // Video Overlay Icons (Play/Pause)
              AnimatedOpacity(
                opacity: _showIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_overlayIcon, color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ),

              // Bottom Gradient
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        begin: const Alignment(0, 0.3),
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom UI (Caption & Actions)
              Positioned(
                bottom: 25,
                left: 20,
                right: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        _displayCaption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionIcon(
                          _isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          "Like",
                          _isLiked ? Colors.redAccent : Colors.white,
                          onTap: _toggleLike,
                        ),
                        const SizedBox(height: 18),
                        _actionIcon(
                          Icons.comment_rounded,
                          "Comment",
                          Colors.white,
                          onTap: _showComments,
                        ),
                        const SizedBox(height: 18),
                        _actionIcon(
                          Icons.edit_note_rounded,
                          "Edit",
                          Colors.white,
                          onTap: _editReel,
                        ),
                        const SizedBox(height: 18),
                        _actionIcon(
                          Icons.share_rounded,
                          "Share",
                          Colors.white,
                          onTap: _shareReel,
                        ),
                        const SizedBox(height: 18),
                        _actionIcon(
                          Icons.delete_outline_rounded,
                          "Delete",
                          Colors.redAccent.withOpacity(0.9),
                          onTap: () => _deleteReel(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
