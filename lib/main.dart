import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:socially_app/firebase_options.dart';
import 'package:socially_app/router/router.dart';
import 'package:socially_app/utils/constants/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:socially_app/services/notification/notification_service.dart';
import 'package:socially_app/providers/theme_provider.dart';

/// 🔹 Background / terminated notification handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2️⃣ Register background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 3️⃣ Initialize notification service
  await NotificationService().initNotification();

  // 4️⃣ Firebase Messaging setup
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  await messaging.subscribeToTopic('all_users');

  // 5️⃣ Initialize Supabase
  await Supabase.initialize(
    url: 'https://zehebtzxoubajakcbpkj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplaGVidHp4b3ViYWpha2NicGtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5NDQ5MTgsImV4cCI6MjA4MzUyMDkxOH0.HBXDNWO69JsbMwntOxzcq1C6Yf8fZ0-121Uxo7XwTwM',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 ThemeProvider එකට සවන් දීම
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'Socially',
      debugShowCheckedModeBanner: false,

      // 🌓 Theme Mode එක සම්බන්ධ කිරීම
      themeMode: themeProvider.themeMode,

      // ⚪ Light Theme Settings
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white, // 🔹 Light mode background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: mainOrangeColor,
          unselectedItemColor: Colors.grey,
        ),
        // අකුරු වල පාට Light mode එකට ගැලපෙන සේ සැකසීම
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      ),

      // ⚫ Dark Theme Settings (ඔයාගේ මුල් කළු පාටම සහිතව)
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF0F0E13,
        ), // 🔹 ඔයාට අවශ්‍ය පරණ කළු පාටම මෙතනට දුන්නා
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: mainOrangeColor,
          unselectedItemColor: mainWhiteColor,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: mainOrangeColor,
          contentTextStyle: TextStyle(color: mainWhiteColor, fontSize: 16),
        ),
        // අකුරු වල පාට Dark mode එකට ගැලපෙන සේ සැකසීම
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),

      routerConfig: RouterClass().router,
    );
  }
}
