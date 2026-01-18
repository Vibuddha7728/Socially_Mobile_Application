import 'package:flutter/material.dart';
import 'package:socially_app/views/responsive/mobile_layout.dart';
import 'package:socially_app/views/responsive/responsive_layout.dart';
import 'package:socially_app/views/responsive/web_layout.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileScreenLayout: MobileScreenLayout(),
      webScreenLayout: WebScreenLayout(),
    );
  }
}
