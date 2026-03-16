import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/ai_support/ai_chat_service.dart';

class HelpChatScreen extends StatefulWidget {
  const HelpChatScreen({super.key});

  @override
  State<HelpChatScreen> createState() => _HelpChatScreenState();
}

class _HelpChatScreenState extends State<HelpChatScreen> {
  final AIChatService _chatService = AIChatService();
  final TextEditingController _controller = TextEditingController();

  // ඇප් එකේ නමට ගැලපෙන පරිදි ආරම්භක පණිවිඩය වෙනස් කරන ලදී
  final List<Map<String, String>> _messages = [
    {
      "role": "ai",
      "message":
          "Hi! 👋 I'm Socially AI. How can I help you with the app today?",
    },
  ];
  bool _isLoading = false;

  // Supabase Video URL
  final String _videoUrl =
      "https://zehebtzxoubajakcbpkj.supabase.co/storage/v1/object/public/help-videos/how_to_post.mp4";

  // වීඩියෝ එක open කරන function එක
  Future<void> _playVideo() async {
    final Uri url = Uri.parse(_videoUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not launch $url");
      }
    } catch (e) {
      debugPrint("Error launching video: $e");
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "message": text});
      _isLoading = true;
    });
    _controller.clear();

    final response = await _chatService.getResponse(text);

    setState(() {
      _messages.add({"role": "ai", "message": response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        // AppBar Title එක Socially Assistant ලෙස වෙනස් කරන ලදී
        title: const Text(
          "Socially Assistant",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF9373F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";

                final bool hasPostKeyword = [
                  "post",
                  "upload",
                  "share",
                  "video",
                  "how to",
                ].any((word) => msg["message"]!.toLowerCase().contains(word));
                final showTutorial = !isUser && hasPostKeyword;

                return Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    _buildBubble(msg["message"]!, isUser),
                    if (showTutorial)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          bottom: 10,
                          top: 4,
                        ),
                        child: ActionChip(
                          avatar: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.black,
                          ),
                          label: const Text(
                            "Watch Tutorial",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _playVideo,
                          backgroundColor: const Color(0xFFF9373F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFF9373F)),
              ),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFFFFC107) : const Color(0xFF262626),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 0),
          bottomRight: Radius.circular(isUser ? 0 : 16),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isUser ? Colors.black : Colors.white,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
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
            onTap: _sendMessage,
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFFFC107),
              child: Icon(Icons.send_rounded, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
