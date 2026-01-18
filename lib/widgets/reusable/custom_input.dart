import 'package:flutter/material.dart';
import 'package:socially_app/utils/constants/colors.dart';

class ReusableInput extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool obscureText;
  final String? Function(String?) validator;

  const ReusableInput({
    super.key, // super.key භාවිතා කිරීම වඩාත් නිවැරදියි
    required this.controller,
    required this.labelText,
    required this.icon,
    required this.obscureText,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderSide: const BorderSide(
        color: Colors.grey,
      ), // Border එක පැහැදිලිව පෙනීමට
      borderRadius: BorderRadius.circular(8),
    );

    return TextFormField(
      controller: controller,
      // මෙන්න මේ style එකෙන් තමයි type කරන අකුරු සුදු පාට කරන්නේ
      style: const TextStyle(color: mainWhiteColor),
      decoration: InputDecoration(
        border: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: mainWhiteColor),
        ),
        enabledBorder: inputBorder,
        labelText: labelText,
        labelStyle: const TextStyle(color: mainWhiteColor),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1), // Input field එකේ ඇතුළත වර්ණය
        prefixIcon: Icon(icon, color: mainWhiteColor, size: 20),
      ),
      obscureText: obscureText,
      validator: validator,
    );
  }
}
