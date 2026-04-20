import 'package:flutter/material.dart';

class GradientProvider {
  static const LinearGradient mainGradient = LinearGradient(
    colors: [
      Color(0xFFE6F4F1),
      Color(0xFFB2DFDB),
      Color(0xFF80CBC4),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}