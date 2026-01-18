import 'package:flutter/material.dart';
// වැදගත්: AdminService එක ඇති තැන අනුව මෙම import එක පරීක්ෂා කරන්න
import '../services/admin_service.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final AdminService _adminService = AdminService(); // Instance එකක් සාදා ගැනීම
  bool _isLoading = false;

  void _handleSend() async {
    // හිස්ව තිබේ නම් නොයවා සිටීම
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both title and message")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String title = _titleController.text.trim();
      String message = _messageController.text.trim();

      // 1. AdminService එකේ ඇති Firestore එකට දත්ත යවන function එක call කිරීම
      await _adminService.sendBroadcastToInboxes(
        title: title,
        message: message,
      );

      // 2. අලුතින් එක් කළ කොටස: ෆෝන් එකේ උඩින් Notification එක යැවීම
      // මෙම function එක අපි AdminService එකට මීට පෙර එකතු කළා
      await _adminService.sendPushNotification(title, message);

      if (mounted) {
        _titleController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Broadcast & Push Sent Successfully!")),
        );
        Navigator.pop(context); // යැවූ පසු නැවත Dashboard එකට යාමට
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13), // Dark dashboard theme
      appBar: AppBar(
        title: const Text(
          "Admin Broadcast",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Notification Title",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.purpleAccent),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _messageController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Broadcast Message",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purpleAccent),
                ),
              ),
            ),
            const SizedBox(height: 50),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.purpleAccent)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _handleSend,
                    child: const Text(
                      "SEND BROADCAST & PUSH",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
