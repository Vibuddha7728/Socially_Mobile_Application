import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Imports නිවැරදි කර ඇත ---
import '../services/admin_service.dart';
import '../views/broadcast_screen.dart';
import '../views/post_management_screen.dart';
import '../views/report_management_screen.dart';
import 'user_management_screen.dart';
import 'analytics_overview_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "ADMIN CONSOLE",
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 18,
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
          // Background Glows
          Positioned(
            top: -100,
            left: -50,
            child: _buildGlowCircle(Colors.indigo.withOpacity(0.15), 300),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _buildGlowCircle(Colors.purple.withOpacity(0.1), 250),
          ),

          StreamBuilder<Map<String, int>>(
            stream: _adminService.getAppStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.purpleAccent),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error loading statistics",
                    style: GoogleFonts.lexend(color: Colors.white),
                  ),
                );
              }

              final stats =
                  snapshot.data ??
                  {'users': 0, 'posts': 0, 'reels': 0, 'reports': 0};

              return SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("System Metrics"),
                      const SizedBox(height: 15),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1.1,
                        children: [
                          _buildGlassStatCard(
                            "USERS",
                            stats['users'].toString(),
                            Colors.purpleAccent,
                            Icons.people_outline,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const UserManagementScreen(),
                              ),
                            ),
                          ),
                          _buildGlassStatCard(
                            "POSTS",
                            stats['posts'].toString(),
                            Colors.blueAccent,
                            Icons.grid_view_rounded,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PostManagementScreen(),
                              ),
                            ),
                          ),
                          _buildGlassStatCard(
                            "REELS",
                            stats['reels'].toString(),
                            Colors.orangeAccent,
                            Icons.play_circle_outline,
                            () {},
                          ),
                          _buildGlassStatCard(
                            "REPORTS",
                            stats['reports'].toString(),
                            Colors.redAccent,
                            Icons.report_gmailerrorred_rounded,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ReportManagementScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 35),
                      _buildSectionTitle("Administrative Tools"),
                      const SizedBox(height: 15),

                      _buildGlassNavCard(
                        "User Management",
                        "Configure access controls & member status",
                        Icons.admin_panel_settings_rounded,
                        Colors.indigoAccent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserManagementScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      _buildGlassNavCard(
                        "Analytics Overview",
                        "Deep dive into engagement & growth metrics",
                        Icons.insights_rounded,
                        Colors.tealAccent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AnalyticsOverviewScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      _buildGlassNavCard(
                        "Broadcast Message",
                        "Send global notifications to all user inboxes",
                        Icons.campaign_rounded,
                        Colors.purpleAccent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BroadcastScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.lexend(
        color: Colors.white38,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(),
      ),
    );
  }

  Widget _buildGlassStatCard(
    String title,
    String val,
    Color col,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.01),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: col.withOpacity(0.8), size: 22),
                const SizedBox(height: 12),
                Text(
                  val,
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    color: col.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNavCard(
    String title,
    String sub,
    IconData icon,
    Color col,
    VoidCallback tap,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: InkWell(
          onTap: tap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: col, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub,
                        style: GoogleFonts.lexend(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
