import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ich bin..."),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/phone-auth',
                  arguments: "woman",
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Frau"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/phone-auth',
                  arguments: "man",
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Mann"),
            ),
          ],
        ),
      ),
    );
  }
}