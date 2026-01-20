import 'package:flutter/material.dart';
import 'package:socially_app/views/main_views/create_screen.dart';
import 'package:socially_app/views/main_views/feed_screen.dart';
import 'package:socially_app/views/main_views/profile_screen.dart';
import 'package:socially_app/views/main_views/reels_screen.dart';
import 'package:socially_app/views/main_views/search_screen.dart';
// 🔹 මෙන්න මේ ලින්ක් එක ඔයාගේ screenshot එකට අනුව හරි ගැස්සුවා
import 'package:socially_app/views/help_center/help_chat_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 🔴 මෙතන 'const' අයින් කළා, එතකොට අර රතු ඉරි නැති වෙනවා
  final List<Widget> _pages = [
    FeedScreen(),
    SearchScreen(),
    CreateScreen(),
    ReelsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      // 🤖 Help Button එක
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpChatScreen()),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.support_agent, color: Colors.white),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Reels',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
