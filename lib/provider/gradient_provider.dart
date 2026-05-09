import 'package:flutter/material.dart';

class GradientProvider {
  static const LinearGradient lightGradient = LinearGradient(
    colors: [
      Color(0xFFE6F4F1),
      Color(0xFFB2DFDB),
      Color(0xFF80CBC4),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
   
   
   // 🌙 DARK
  static const LinearGradient darkGradient = LinearGradient(
    colors: [
      Color(0xFF121212),
      Color(0xFF1E1E1E),
      Color(0xFF2A2A2A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}