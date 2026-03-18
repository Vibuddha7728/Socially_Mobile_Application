// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socially_app/models/user_model.dart';
import 'package:socially_app/services/auth/auth_service.dart';
import 'package:socially_app/services/users/user_service.dart';
import 'package:socially_app/services/users/user_storage.dart';
import 'package:socially_app/utils/constants/colors.dart';
import 'package:socially_app/widgets/reusable/custom_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late AnimationController _controller;
  late Animation<double> _animation;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController(); // Added age controller
  final _jobTitleController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _jobTitleController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _createUser(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a profile picture'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      UserCredential userCredential = await authService
          .signUpWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      final String uid = userCredential.user!.uid;
      String imageUrl = await UserProfileStorageService().uploadImage(
        profileImage: _imageFile!,
        userEmail: _emailController.text.trim(),
      );

      // --- Updated UserModel with isBlocked to fix Admin Errors ---
      await UserService().saveUser(
        UserModel(
          userId: uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          age: int.tryParse(_ageController.text.trim()) ?? 0,
          jobTitle: _jobTitleController.text.trim(),
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          password: "",
          followersCount: 0,
          followingCount: 0,
          role: "user",
          isBlocked: false, // මෙන්න මේක අලුතින් එකතු කළා
        ),
      );
      if (!mounted) return;
      context.go('/main-screen');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0C29),
                  Color(0xFF050505),
                  Color(0xFF24243E),
                ],
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildMovingIcon(
                    Icons.favorite,
                    45,
                    Colors.pinkAccent,
                    top: 120,
                    left: 40,
                    moveX: 20,
                    moveY: 60,
                  ),
                  _buildMovingIcon(
                    Icons.chat_bubble_rounded,
                    38,
                    Colors.blueAccent,
                    top: 280,
                    right: 30,
                    moveX: -40,
                    moveY: 40,
                  ),
                  _buildMovingIcon(
                    Icons.person_add_alt_1_rounded,
                    48,
                    Colors.purpleAccent,
                    bottom: 200,
                    left: 60,
                    moveX: 30,
                    moveY: -50,
                  ),
                  _buildMovingIcon(
                    Icons.thumb_up_rounded,
                    35,
                    Colors.cyanAccent,
                    bottom: 120,
                    right: 50,
                    moveX: -20,
                    moveY: -30,
                  ),
                  _buildMovingIcon(
                    Icons.share_rounded,
                    40,
                    Colors.orangeAccent,
                    top: 450,
                    left: 20,
                    moveX: 40,
                    moveY: 20,
                  ),
                  _buildMovingIcon(
                    Icons.notifications_active,
                    32,
                    Colors.yellowAccent,
                    top: 80,
                    right: 100,
                    moveX: -10,
                    moveY: 30,
                  ),
                  Positioned(
                    top: 200 * _animation.value,
                    right: -100,
                    child: _buildBlurCircle(
                      300,
                      mainPurpleColor.withOpacity(0.15),
                    ),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(),
                  const SizedBox(height: 35),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildImagePicker(),
                        const SizedBox(height: 45),
                        _buildInputField(
                          _nameController,
                          'Full Name',
                          Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 18),
                        _buildInputField(
                          _emailController,
                          'Email Address',
                          Icons.alternate_email_rounded,
                          isEmail: true,
                        ),
                        const SizedBox(height: 18),
                        _buildInputField(
                          _phoneController,
                          'Phone Number',
                          Icons.phone_rounded,
                          isPhone: true,
                        ),
                        const SizedBox(height: 18),

                        // Age Field
                        _buildInputField(
                          _ageController,
                          'Age',
                          Icons.calendar_today_rounded,
                          isNumber: true,
                        ),
                        const SizedBox(height: 18),

                        _buildInputField(
                          _jobTitleController,
                          'Job Title',
                          Icons.work_outline_rounded,
                        ),
                        const SizedBox(height: 18),
                        _buildInputField(
                          _passwordController,
                          'Password',
                          Icons.lock_outline_rounded,
                          isPass: true,
                        ),
                        const SizedBox(height: 18),
                        _buildInputField(
                          _confirmPasswordController,
                          'Confirm Password',
                          Icons.lock_reset_rounded,
                          isPass: true,
                          isConfirm: true,
                        ),
                        const SizedBox(height: 45),
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: mainPurpleColor,
                                ),
                              )
                            : _buildSubmitButton(),
                        const SizedBox(height: 30),
                        _buildFooter(),
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Utility Widgets (Animations & Form UI) ---

  Widget _buildMovingIcon(
    IconData icon,
    double size,
    Color color, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double moveX,
    required double moveY,
  }) {
    return Positioned(
      top: top != null ? top + (moveY * _animation.value) : null,
      bottom: bottom != null ? bottom + (moveY * _animation.value) : null,
      left: left != null ? left + (moveX * _animation.value) : null,
      right: right != null ? right + (moveX * _animation.value) : null,
      child: Opacity(
        opacity: 0.25,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 30)],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.03),
            boxShadow: [
              BoxShadow(
                color: mainPurpleColor.withOpacity(0.2),
                blurRadius: 60,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Image(image: AssetImage('assets/logo.png'), height: 70),
        ),
        const SizedBox(height: 20),
        const Text(
          "Create Account",
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: mainPurpleColor.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: mainPurpleColor.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF1A1A1A),
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : const NetworkImage('https://i.stack.imgur.com/l60Hf.png')
                        as ImageProvider,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: mainPurpleColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_a_photo_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPass = false,
    bool isEmail = false,
    bool isConfirm = false,
    bool isNumber = false,
    bool isPhone = false,
  }) {
    return ReusableInput(
      controller: controller,
      labelText: label,
      icon: icon,
      obscureText: isPass,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (isEmail && !v.contains('@')) return 'Invalid Email';
        if (isPass && v.length < 6) return 'Password too short';
        if (isConfirm && v != _passwordController.text) {
          return 'Passwords do not match';
        }
        if (isNumber && int.tryParse(v) == null) return 'Enter a valid number';
        if (isPhone && !RegExp(r'^\d{10,12}$').hasMatch(v)) {
          return 'Enter a valid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: mainPurpleColor.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: mainPurpleColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        onPressed: () => _createUser(context),
        child: const Text(
          'CREATE ACCOUNT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: const Text(
            "Log In",
            style: TextStyle(
              color: mainPurpleColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
