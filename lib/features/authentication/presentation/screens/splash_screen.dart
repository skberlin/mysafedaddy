import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Nutzer ist eingeloggt → später HomeScreen
      Navigator.pushReplacementNamed(context, '/role-selection');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 80, color: Colors.pink),
            SizedBox(height: 20),
            Text(
              "MySafeDaddy",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("Sicherheit beim Dating", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}