import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

class CrashTestScreen extends StatelessWidget {
  const CrashTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crashlytics Test"),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bug_report, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "Testing Crashlytics",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
  // Crashlytics logic directly here
  FirebaseCrashlytics.instance.log("Button Pressed");
  try {
     throw Exception("Test Error");
  } catch (e, s) {
     FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
  }
              },
              child: const Text("Force Test Crash", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}