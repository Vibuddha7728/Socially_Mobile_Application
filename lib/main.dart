import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // අලුතින් එක් කළා
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socially_app/firebase_options.dart';
import 'package:socially_app/router/router.dart';
import 'package:socially_app/utils/constants/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// බැක්ග්‍රවුන්ඩ් එකේදී මැසේජ් එකක් ආවොත් හැසිරවිය යුතු ආකාරය
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Initialize Firebase (Firestore, Auth, etc.)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 Push Notifications සඳහා අවශ්‍ය සේවාවන් ආරම්භ කිරීම
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // නොටිෆිකේෂන් පෙන්වීමට අවසර ඉල්ලීම (iPhone සහ අලුත් Android ෆෝන් සඳහා)
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // ඇඩ්මින් පැනල් එකෙන් යවන පණිවුඩ ලැබීමට "all_users" කියන Topic එකට සම්බන්ධ වීම
  await messaging.subscribeToTopic('all_users');

  // ඇප් එක වහලා තියෙද්දි පණිවුඩ ලැබීම පාලනය කිරීම
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔹 Initialize Supabase (Storage only)
  await Supabase.initialize(
    url: 'https://zehebtzxoubajakcbpkj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplaGVidHp4b3ViYWpha2NicGtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5NDQ5MTgsImV4cCI6MjA4MzUyMDkxOH0.HBXDNWO69JsbMwntOxzcq1C6Yf8fZ0-121Uxo7XwTwM',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Socially',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.poppins().fontFamily,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // optional dark bg
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: mainOrangeColor,
          unselectedItemColor: mainWhiteColor,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: mainOrangeColor,
          contentTextStyle: TextStyle(color: mainWhiteColor, fontSize: 16),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      routerConfig: RouterClass().router,
    );
  }
}
