import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';

class ReportManagementScreen extends StatelessWidget {
  const ReportManagementScreen({super.key});

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
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.02)),
          ),
        ),
        title: Text(
          "USER REPORTS",
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
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
      body: StreamBuilder<QuerySnapshot>(
        stream: adminService.getAllReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No active reports found",
                style: GoogleFonts.lexend(color: Colors.white38),
              ),
            );
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final reportData = reports[index].data() as Map<String, dynamic>;
              final String reportId = reports[index].id;

              return _buildReportCard(
                context,
                reportId,
                reportData,
                adminService,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
    AdminService service,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.01),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Reported User: ${data['reportedUserName'] ?? 'Unknown'}",
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Reason: ${data['reason'] ?? 'No reason provided'}",
            style: GoogleFonts.lexend(color: Colors.white70, fontSize: 12),
          ),
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => service.dismissReport(id),
                child: Text(
                  "Dismiss",
                  style: GoogleFonts.lexend(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                  elevation: 0,
                ),
                onPressed: () {
                  // මෙතනදී ඔයාට පුළුවන් කෙලින්ම User Management එකට Navigate කරවන්න
                  // හෝ අදාළ User ID එක අරගෙන ToggleBlock function එක call කරන්න.
                  service.toggleUserBlock(data['reportedUserId'], true);
                  service.dismissReport(id);
                },
                child: Text(
                  "Block User",
                  style: GoogleFonts.lexend(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
