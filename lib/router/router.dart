import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:socially_app/models/user_model.dart';
import 'package:socially_app/views/auth_views/login.dart';
import 'package:socially_app/views/auth_views/register.dart';
import 'package:socially_app/views/main_screen.dart';
import 'package:socially_app/views/main_views/single_user.dart';
import 'package:socially_app/views/wrapper.dart';

class RouterClass {
  final router = GoRouter(
    initialLocation: "/",
    errorPageBuilder: (context, state) {
      return const MaterialPage<dynamic>(
        child: Scaffold(body: Center(child: Text("this page is not found!!"))),
      );
    },
    routes: [
      //wrapper
      GoRoute(
        path: "/",
        name: "wrapper",
        builder: (context, state) {
          return const Wrapper();
        },
      ),
      // login Page
      GoRoute(
        name: "login",
        path: "/login",
        builder: (context, state) {
          return LoginScreen();
        },
      ),

      //register Page
      GoRoute(
        name: "register",
        path: "/register",
        builder: (context, state) {
          return RegisterScreen();
        },
      ),

      // MainScreen
      GoRoute(
        name: "main-screen",
        path: "/main-screen",
        builder: (context, state) {
          return const MainScreen();
        },
      ),

      //profile screen
      GoRoute(
        name: "profile-screen",
        path: "/profile-screen",
        builder: (context, state) {
          final UserModel user = state.extra as UserModel;
          return SingleUserScreen(user: user);
        },
      ),
    ],
  );
}
