import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socially_app/models/reel_model.dart';
import 'package:socially_app/services/reels/reel_service.dart';
import 'package:socially_app/widgets/main/reels/add_reel.dart';
import 'package:socially_app/widgets/main/reels/reel_widget.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color එක app theme එකට ගැලපෙන සේ කළු පැහැයට සමීප කර ඇත
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text(
          'Reels',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ReelService().getReels(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC913B9)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    color: Colors.white24,
                    size: 80,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'No reels available',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final reels = snapshot.data!.docs
              .map((doc) => Reel.fromJson(doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            // පිරිසිදු පෙනුමක් සඳහා padding එක් කර ඇත
            padding: const EdgeInsets.symmetric(vertical: 10),
            physics: const BouncingScrollPhysics(),
            itemCount: reels.length,
            itemBuilder: (context, index) {
              final reel = reels[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: ReelWidget(reel: reel),
              );
            },
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFC913B9), Color(0xFFF9373F)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC913B9).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddReelModal(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
        ),
      ),
    );
  }

  void _showAddReelModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Full screen height එක පාලනය කිරීමට
      backgroundColor:
          Colors.transparent, // Glass effect එක සඳහා transparent කළ යුතුය
      barrierColor: Colors.black54, // පසූබිම අඳුරු කිරීමට
      builder: (context) => const AddReelModal(),
    );
  }
}
