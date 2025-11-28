import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 90, color: Colors.pink),
            SizedBox(height: 30),
            Text(
              "Sicherheit bei jedem Treffen",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "Starte Timer, lade Männer ein,\n"
              "hinterlege Notfallkontakte\n"
              "und bleibe geschützt.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/role-selection');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Los geht’s"),
            )
          ],
        ),
      ),
    );
  }
}