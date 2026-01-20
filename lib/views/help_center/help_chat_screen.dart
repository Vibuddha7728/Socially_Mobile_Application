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
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final String _videoUrl =
      "https://zehebtzxoubajakcbpkj.supabase.co/storage/v1/object/public/help-videos/how_to_post.mp4";

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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Support Assistant"),
        backgroundColor: Colors.black,
        elevation: 0,
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

                // වීඩියෝ එක පෙන්විය යුතුදැයි බැලීම
                final bool hasPostKeyword = [
                  "post",
                  "upload",
                  "share",
                  "video",
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
                        padding: const EdgeInsets.only(left: 8, bottom: 10),
                        child: ActionChip(
                          avatar: const Icon(
                            Icons.play_circle,
                            color: Colors.orange,
                          ),
                          label: const Text(
                            "Watch Tutorial",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () => launchUrl(Uri.parse(_videoUrl)),
                          backgroundColor: Colors.grey[850],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              color: Colors.orange,
              backgroundColor: Colors.black,
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isUser ? Colors.orangeAccent : Colors.grey[900],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 0),
          bottomRight: Radius.circular(isUser ? 0 : 20),
        ),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ask anything...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.orange,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
