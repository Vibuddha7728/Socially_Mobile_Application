// ignore_for_file: avoid_print
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:socially_app/services/auth/auth_service.dart';
import 'package:socially_app/utils/constants/colors.dart';
import 'package:socially_app/widgets/reusable/custom_button.dart';
import 'package:socially_app/widgets/reusable/custom_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Glass Error Popup
  void _showGlassError(String message) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_person_rounded,
                          color: Colors.redAccent,
                          size: 50,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ACCESS DENIED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ReusableButton(
                          text: 'OK',
                          width: double.infinity,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- PRE-LOGIN BLOCK CHECK LOGIC ---
  Future<void> _processAuth(Future<UserCredential?> authMethod) async {
    setState(() => _isLoading = true);
    try {
      final cred = await authMethod;

      if (cred != null && cred.user != null) {
        // 1. මුලින්ම Firestore එකෙන් Block ද කියලා බලනවා
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .get();

        final bool isBlocked = doc.data()?['isBlocked'] ?? false;

        if (isBlocked) {
          // 2. Block නම් වහාම Sign Out කරනවා (Navigation එකට කලින්)
          await AuthService().signOut();
          if (mounted) {
            _showGlassError(
              'Your account has been blocked by the administrator.',
            );
          }
        } else {
          // 3. Block නැත්නම් විතරක් ඇතුළට යවනවා
          if (mounted) {
            context.go('/main-screen');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showGlassError(e.toString().replaceAll('Exception:', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 25),
              child: Column(
                children: [
                  const Center(
                    child: Image(
                      image: AssetImage('assets/logo.png'),
                      height: 80,
                    ),
                  ),
                  SizedBox(height: size.height * 0.08),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        ReusableInput(
                          controller: _emailController,
                          labelText: 'Email',
                          icon: Icons.email_outlined,
                          obscureText: false,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ReusableInput(
                          controller: _passwordController,
                          labelText: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter password';
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        ReusableButton(
                          text: 'Log in',
                          width: size.width,
                          onPressed: _isLoading
                              ? () {}
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    _processAuth(
                                      AuthService().signInWithEmailAndPassword(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text
                                            .trim(),
                                      ),
                                    );
                                  }
                                },
                        ),
                        const SizedBox(height: 25),
                        const Text("OR", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 25),
                        ReusableButton(
                          text: 'Sign in with Google',
                          width: size.width,
                          onPressed: _isLoading
                              ? () {}
                              : () => _processAuth(
                                  AuthService().signInWithGoogle(),
                                ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text(
                            'Don\'t have an account? Sign up',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(color: mainWhiteColor),
              ),
            ),
        ],
      ),
    );
  }
}
