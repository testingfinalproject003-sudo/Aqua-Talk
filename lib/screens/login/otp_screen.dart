import 'dart:async';
import 'package:aqua_talk/screens/setting/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aqua_talk/provider/gradient_provider.dart';
import 'splash_screen.dart';


class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  int seconds = 30;
  Timer? timer;
  bool isLoading = false;
  bool isResending = false;

  // These can change on resend
  late String _verificationId;
  int? _resendToken;

  final List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes =
      List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    seconds = 30;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => seconds--);
      }
    });
  }

  // 🔥 Actually re-triggers Firebase to send a new OTP
  Future<void> _resendOtp() async {
    if (!mounted) return;
    setState(() => isResending = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,

      // Pass resendToken if we have one (faster resend)
      forceResendingToken: _resendToken,

      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      },

      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() => isResending = false);
        _showError(e.message ?? 'Failed to resend OTP');
      },

      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() {
          isResending = false;
          // Update verificationId and resendToken for next resend
          _verificationId = verificationId;
          _resendToken = resendToken;
        });

        // Clear all OTP boxes
        for (var c in controllers) {
          c.clear();
        }
        focusNodes[0].requestFocus();

        // Restart the countdown
        startTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully ✅'),
            backgroundColor: Color(0xFF0F3D3E),
          ),
        );
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> verifyOtp() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    String enteredOtp = controllers.map((c) => c.text).join();

    if (enteredOtp.length != 6) {
      setState(() => isLoading = false);
      _showError("Enter complete OTP");
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId, 
        smsCode: enteredOtp.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // if (!mounted) return;
      setState(() => isLoading = false);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showError(e.message ?? "Invalid OTP ❌");

      for (var c in controllers) {
        c.clear();
      }
      focusNodes[0].requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showError("Something went wrong ❌");
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      (route) => false,
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
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

  bool get isComplete =>
      controllers.every((e) => e.text.length == 1);

  @override
  void dispose() {
    timer?.cancel();
    for (var f in focusNodes) {
      f.dispose();
    }
    for (var c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget otpBox(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
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
            borderSide: const BorderSide(
              color: Color(0xFF0F3D3E),
              width: 2,
            ),
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
                children: List.generate(
                  6,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: otpBox(i),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              if (isLoading)
                const CircularProgressIndicator(color: Color(0xFF0F3D3E))
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3D3E),
                    minimumSize: const Size(250, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isComplete ? verifyOtp : null,
                  child: const Text(
                    "VERIFY",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Resend section
              if (isResending)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0F3D3E),
                  ),
                )
              else if (seconds > 0)
                Text(
                  "Resend OTP in $seconds s",
                  style: const TextStyle(color: Colors.black54),
                )
              else
                TextButton(
                  onPressed: _resendOtp,
                  child: const Text(
                    "Resend OTP",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}