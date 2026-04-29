import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Firebase Import Enabled
import 'package:aqua_talk/provider/gradient_provider.dart';
import 'splash_screen.dart';

class OtpScreen extends StatefulWidget {
  // 🔥 Receives data from LoginScreen
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key, 
    required this.verificationId, 
    required this.phoneNumber
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  int seconds = 30;
  Timer? timer;
  bool isLoading = false; // 🔥 Verification ke waqt loader dikhane ke liye
  final List<TextEditingController> controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    seconds = 30;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
      } else {
        setState(() => seconds--);
      }
    });
  }

  // 🔥 REAL FIREBASE VERIFICATION
  Future<void> verifyOtp() async {
    setState(() => isLoading = true);
    ScaffoldMessenger.of(context).clearSnackBars();
    
    String enteredOtp = "";
    for (var controller in controllers) {
      enteredOtp += controller.text;
    }

    try {
      // Create credential with real verificationId and entered OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId, 
        smsCode: enteredOtp,
      );

      // Sign in with Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      setState(() => isLoading = false);
      _navigateToHome();
    } catch (e) {
      setState(() => isLoading = false);
      _showError("Invalid OTP! Try again ❌");
      // OTP boxes clear karein
      for (var c in controllers) { c.clear(); }
      focusNodes[0].requestFocus();
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)), 
        backgroundColor: const Color(0xFF0F3D3E), 
      ),
    );
  }

  void onChanged(String value, int index) {
    if (value.length > 1) {
      for (int i = 0; i < 6 && i < value.length; i++) {
        controllers[i].text = value[i];
      }
      FocusScope.of(context).unfocus();
    } else if (value.isNotEmpty) {
      if (index < 5) focusNodes[index + 1].requestFocus();
    } else {
      if (index > 0) focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  bool get isComplete => controllers.every((e) => e.text.length == 1);

  @override
  void dispose() {
    timer?.cancel();
    for (var f in focusNodes) { f.dispose(); }
    for (var c in controllers) { c.dispose(); }
    super.dispose();
  }

  Widget otpBox(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        style: const TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: Color(0xFF0F3D3E),
        ),
        controller: controllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => onChanged(v, index),
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black26),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0F3D3E), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GradientProvider.mainGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Enter OTP to Verify", 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F3D3E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Code sent to ${widget.phoneNumber}",
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: otpBox(i),
                )),
              ),
              const SizedBox(height: 40),
              
              // 🔥 Loading Indicator or Button
              if (isLoading)
                const CircularProgressIndicator(color: Color(0xFF0F3D3E))
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3D3E), 
                    minimumSize: const Size(250, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isComplete ? verifyOtp : null,
                  child: const Text(
                    "VERIFY", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 20),
              if (seconds > 0)
                Text("Resend in $seconds s", style: const TextStyle(color: Colors.black54))
              else
                TextButton(
                  onPressed: startTimer,
                  child: const Text(
                    "Resend OTP", 
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold,),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}