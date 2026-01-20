import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:socially_app/models/user_model.dart';
import 'package:socially_app/services/users/user_service.dart';
import 'package:socially_app/utils/constants/colors.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await UserService().getAllUsers(); // Fetch all users
      setState(() {
        _users = users;
        _filteredUsers = users;
      });
    } catch (error) {
      print('Error fetching users: $error');
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users
          .where(
            (user) => user.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  void _navigateToUserProfile(UserModel user) {
    GoRouter.of(context).push('/profile-screen', extra: user);
  }

  @override
  Widget build(BuildContext context) {
    // 🌓 Theme එක පරීක්ෂා කිරීම
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final inputBorder = OutlineInputBorder(
      borderSide: Divider.createBorderSide(context),
      borderRadius: BorderRadius.circular(8),
    );

    return Scaffold(
      // 🔹 Background එක Theme එකට අනුව මාරු වේ
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Search Users'),
        // AppBar එකේ අකුරු වල පාට Theme එකට අනුව සැකසීම
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              // ✅ පාට කෙලින්ම දෙනවා වෙනුවට Theme එකට අනුව මාරු වන සේ සැකසුවා
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Search',
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                filled: true,
                // ✅ Search bar එකේ ඇතුළත වර්ණය Light mode එකේදී අළු පාටට හුරු වේ
                fillColor: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[200],
                border: inputBorder,
                focusedBorder: inputBorder,
                enabledBorder: inputBorder,
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white : Colors.black54,
                  size: 20,
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.imageUrl.isNotEmpty
                        ? NetworkImage(user.imageUrl)
                        : const AssetImage('assets/logo.png') as ImageProvider,
                  ),
                  // ✅ List එකේ අකුරු වල පාට Theme එකට අනුව මාරු වේ
                  title: Text(
                    user.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    user.jobTitle,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  onTap: () => _navigateToUserProfile(user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
