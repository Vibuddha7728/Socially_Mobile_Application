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
    // 🌓 Theme එක Dark ද නැද්ද යන්න පරීක්ෂා කිරීම (අකුරු වල වර්ණ පාලනයට)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 🔹 Background color එක theme එකට අනුව ඉබේම මාරු වේ.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          'Reels',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            // 🌓 පසුබිම අනුව අකුරු වල වර්ණය වෙනස් වීම
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // AppBar එකේ icons වල වර්ණය වෙනස් කිරීම
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
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
                    color: isDark ? Colors.white24 : Colors.black26,
                    size: 80,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'No reels available',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final reels = snapshot.data!.docs
              .map((doc) => Reel.fromJson(doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
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

      // ✅ Plus Button එක (FloatingActionButton)
      floatingActionButton: Container(
        height: 60,
        width: 60,
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
          child: const Icon(Icons.add_rounded, size: 35, color: Colors.white),
        ),
      ),

      // 📍 Button එක දකුණු පැත්තේ (Right Side) ස්ථානගත කිරීමට මෙය භාවිතා කළා.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showAddReelModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => const AddReelModal(),
    );
  }
}
