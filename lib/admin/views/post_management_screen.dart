import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_service.dart';

class PostManagementScreen extends StatefulWidget {
  const PostManagementScreen({super.key});

  @override
  State<PostManagementScreen> createState() => _PostManagementScreenState();
}

class _PostManagementScreenState extends State<PostManagementScreen> {
  final AdminService _adminService = AdminService();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13), // Dark Background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "MANAGE POSTS",
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.02)),
          ),
        ),
      ),
      body: Stack(
        children: [
          // --- Background Glows (Dashboard එකට සමානයි) ---
          Positioned(
            top: 50,
            right: -50,
            child: _buildGlowCircle(Colors.blueAccent.withOpacity(0.1), 250),
          ),
          Positioned(
            bottom: 50,
            left: -50,
            child: _buildGlowCircle(Colors.purpleAccent.withOpacity(0.05), 300),
          ),

          SafeArea(
            child: Column(
              children: [
                // --- Glass Search Bar ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value.toLowerCase()),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Search by caption or User ID...",
                          hintStyle: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('feed')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.blueAccent,
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No posts found",
                            style: TextStyle(color: Colors.white38),
                          ),
                        );
                      }

                      // Filtering logic
                      var filteredPosts = snapshot.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String caption = (data['postCaption'] ?? "")
                            .toString()
                            .toLowerCase();
                        String userId = (data['userId'] ?? "")
                            .toString()
                            .toLowerCase();
                        return caption.contains(_searchQuery) ||
                            userId.contains(_searchQuery);
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          var post = filteredPosts[index];
                          var data = post.data() as Map<String, dynamic>;

                          return _buildGlassPostCard(context, post.id, data);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Glass Post Card Widget ---
  Widget _buildGlassPostCard(
    BuildContext context,
    String postId,
    Map<String, dynamic> data,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.01),
                ],
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: data['postUrl'] != null
                      ? Image.network(
                          data['postUrl'],
                          width: 65,
                          height: 65,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 65,
                          height: 65,
                          color: Colors.white10,
                          child: const Icon(Icons.image, color: Colors.white24),
                        ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['postCaption'] ?? 'No Caption',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "UID: ${data['userId']?.toString().substring(0, 10)}...",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                  onPressed: () => _confirmDelete(context, postId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
        child: Container(),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A191F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Delete Post?",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: const Text(
            "This action cannot be undone.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await _adminService.deletePost(postId);
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        ),
      ),
    );
  }
}
