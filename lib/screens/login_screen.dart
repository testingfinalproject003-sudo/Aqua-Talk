import 'dart:ui'; // For glass effect
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Firebase Import
import 'package:aqua_talk/provider/gradient_provider.dart';
import 'otp_screen.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance; // 🔥 Auth Instance

  bool isValid = false;
  bool isLoading = false; // 🔥 Loading state
  String? errorMsg; // Dynamic error message

  // 🌍 Country Data with Validation Rules
  final List<Map<String, dynamic>> countries = [
    {"code": "+92", "flag": "🇵🇰", "name": "Pakistan", "prefix": "03", "length": 11},
    {"code": "+91", "flag": "🇮🇳", "name": "India", "prefix": "", "length": 10},
    {"code": "+1", "flag": "🇺🇸", "name": "USA", "prefix": "", "length": 10},
    {"code": "+44", "flag": "🇬🇧", "name": "UK", "prefix": "07", "length": 11},
    {"code": "+61", "flag": "🇦🇺", "name": "Australia", "prefix": "04", "length": 10},
    {"code": "+81", "flag": "🇯🇵", "name": "Japan", "prefix": "0", "length": 11},
  ];

  late Map<String, dynamic> selectedCountry;

  @override
  void initState() {
    super.initState();
    selectedCountry = countries[0]; // Default Pakistan
  }

  // 🔥 FIREBASE: Send OTP Logic
  Future<void> _sendOTP() async {
    setState(() => isLoading = true);
    
    // Prefix agar 03 hai aur code +92, to hum format sahi karte hain (+923...)
    String number = phoneController.text;
    if (selectedCountry['code'] == "+92" && number.startsWith('0')) {
      number = number.substring(1);
    }
    
    String fullNumber = "${selectedCountry['code']}$number";

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? "Error occurred"), backgroundColor: Colors.red),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => isLoading = false);
          // 🚀 Navigating to OTP Screen with real data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                verificationId: verificationId, 
                phoneNumber: fullNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => isLoading = false);
      log("Error: $e");
    }
  }

  // ✅ Number validation logic
  void validateNumber(String value) {
    String prefix = selectedCountry['prefix'];
    int requiredLength = selectedCountry['length'];
    
    setState(() {
      if (value.isEmpty) {
        isValid = false;
        errorMsg = null;
      } 
      else if (prefix.isNotEmpty && !value.startsWith(prefix)) {
        isValid = false;
        errorMsg = "Invalid format! Starts with $prefix";
      } 
      else if (value.length < requiredLength) {
        isValid = false;
        errorMsg = "Enter $requiredLength digits";
      } 
      else {
        isValid = true;
        errorMsg = null; 
      }
    });
  }

  void openCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: countries.length,
                itemBuilder: (_, index) {
                  final country = countries[index];
                  return ListTile(
                    leading: Text(country["flag"], style: const TextStyle(fontSize: 22)),
                    title: Text("${country["name"]} (${country["code"]})", 
                      style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        selectedCountry = country;
                        validateNumber(phoneController.text);
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, 
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Enter your phone number", style: TextStyle(color: Color(0xFF004D40))),
        backgroundColor: const Color(0xFFB2DFDB),
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(gradient: GradientProvider.mainGradient),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  const Text(
                    "Aqua Talk will need to verify your phone number.",
                    style: TextStyle(fontSize: 18, color: Color(0xFF004D40)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // 📱 INPUT ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: openCountryPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text("${selectedCountry['flag']} ${selectedCountry['code']} ▼", 
                            style: const TextStyle(fontSize: 16, color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                              controller: phoneController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(selectedCountry['length']),
                              ],
                              onChanged: validateNumber,
                              decoration: InputDecoration(
                                hintText: "Enter number",
                                hintStyle: const TextStyle(color: Colors.black),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: errorMsg != null ? Colors.red : Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: errorMsg != null ? Colors.red : const Color(0xFF0F3D3E), 
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            if (errorMsg != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 5),
                                child: Text(
                                  errorMsg!,
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 🚀 BUTTON (With Loading)
                  if (isLoading)
                    const CircularProgressIndicator(color: Color(0xFF0F3D3E))
                  else
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isValid
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F3D3E),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: _sendOTP, // 🔥 Function call updated
                              child: const Text("Send OTP", style: TextStyle(color: Colors.white, fontSize: 18)),
                            )
                          : const SizedBox(),
                    ),
                ],
              ),
            ),

            // 🔽 BOTTOM BRANDING
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("from", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    const Text("JM", style: TextStyle(color: Color(0xFF1F6F6B), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}