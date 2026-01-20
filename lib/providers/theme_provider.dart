import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // ආරම්භක තේමාව (Dark Mode)
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // තේමාව මාරු කරන Function එක
  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners(); // මුළු ඇප් එකටම වෙනස දන්වයි
  }
}
