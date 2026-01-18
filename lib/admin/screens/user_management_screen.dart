import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminService adminService = AdminService();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.white.withOpacity(0.02)),
          ),
        ),
        title: Text(
          "USER DIRECTORY",
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Aesthetic Glows
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlowCircle(Colors.purple.withOpacity(0.1), 250),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: _buildGlowCircle(Colors.blueAccent.withOpacity(0.05), 200),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: adminService.getAllUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.purpleAccent,
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No members found",
                            style: GoogleFonts.lexend(color: Colors.white38),
                          ),
                        );
                      }

                      final users = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final userData =
                              users[index].data() as Map<String, dynamic>;
                          final String userId = users[index].id;
                          final bool isBlocked = userData['isBlocked'] ?? false;

                          String joinedDate = "N/A";
                          if (userData['createdAt'] != null) {
                            DateTime dt = (userData['createdAt'] as Timestamp)
                                .toDate();
                            joinedDate = DateFormat('MMM dd, yyyy').format(dt);
                          }

                          return _buildProfessionalUserCard(
                            context,
                            userId,
                            userData,
                            isBlocked,
                            joinedDate,
                            adminService,
                          );
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

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Search member via name or email...",
            hintStyle: GoogleFonts.lexend(color: Colors.white24, fontSize: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Colors.white38,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalUserCard(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
    bool isBlocked,
    String date,
    AdminService service,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ],
        ),
        border: Border.all(
          color: isBlocked
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Profile Picture with subtle glow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isBlocked
                        ? Colors.red.withOpacity(0.1)
                        : Colors.purple.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white10,
                backgroundImage:
                    (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
                    ? NetworkImage(data['imageUrl'])
                    : const AssetImage('assets/logo.png') as ImageProvider,
              ),
            ),
            const SizedBox(width: 14),

            // User Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Socially Member',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['email'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 10,
                        color: Colors.purpleAccent.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: GoogleFonts.lexend(
                          color: Colors.purpleAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Button
            _buildActionButton(context, service, uid, isBlocked, data['name']),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    AdminService service,
    String uid,
    bool isBlocked,
    String? name,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showConfirmDialog(context, service, uid, isBlocked, name),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isBlocked
                ? Colors.green.withOpacity(0.1)
                : Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isBlocked
                  ? Colors.green.withOpacity(0.3)
                  : Colors.redAccent.withOpacity(0.3),
            ),
          ),
          child: Text(
            isBlocked ? "UNBLOCK" : "BLOCK",
            style: GoogleFonts.lexend(
              color: isBlocked ? Colors.greenAccent : Colors.redAccent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    AdminService service,
    String uid,
    bool status,
    String? name,
  ) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A191E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          title: Text(
            status ? "Confirm Unblock" : "Confirm Block",
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: Text(
            "Are you sure you want to ${status ? 'restore access for' : 'restrict'} ${name ?? 'this member'}?",
            style: GoogleFonts.lexend(color: Colors.white60, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.lexend(color: Colors.white24, fontSize: 13),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: status ? Colors.green : Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () {
                  service.toggleUserBlock(uid, !status);
                  Navigator.pop(context);
                },
                child: Text(
                  status ? "Unblock" : "Block User",
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
