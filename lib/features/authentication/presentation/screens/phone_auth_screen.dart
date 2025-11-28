import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthScreen extends StatefulWidget {
  final String role; // "woman" oder "man"

  const PhoneAuthScreen({Key? key, required this.role}) : super(key: key);

  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _controller = TextEditingController();
  bool loading = false;

  /// Prüft, ob die eingegebene Nummer im internationalen DE-Format ist:
  /// Beispiel: +49 174 1234567 → +49 gefolgt von 9–14 Ziffern
  bool _validateGermanNumber(String phone) {
    final cleaned = phone.replaceAll(' ', '');
    final reg = RegExp(r'^\+49\d{9,14}$'); // +49 und danach 9–14 Ziffern
    return reg.hasMatch(cleaned);
  }

  Future<void> _sendCode() async {
    String phone = _controller.text.trim();
    phone = phone.replaceAll(' ', '');

    if (!_validateGermanNumber(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Bitte gib eine gültige deutsche Nummer im Format +49… ein.\n"
            "Beispiel: +49 174 1234567",
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Optional: Auto-Login später nachrüsten
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Verifizierung fehlgeschlagen')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() => loading = false);

        Navigator.pushNamed(
          context,
          '/verify-code',
          arguments: {
            'phoneNumber': phone,
            'verificationId': verificationId,
            'role': widget.role,
          },
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Kann leer bleiben
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleText = widget.role == 'woman' ? 'Frau' : 'Mann';

    return Scaffold(
      appBar: AppBar(
        title: Text("SMS-Verifizierung ($roleText)"),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bitte gib deine deutsche Telefonnummer im internationalen Format ein.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Beispiel: +49 174 1234567\n"
              "(+49 = Deutschland, danach deine Nummer ohne führende 0)",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Telefonnummer",
                hintText: "+49 174 1234567",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: loading ? null : _sendCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SMS-Code senden"),
            ),
          ],
        ),
      ),
    );
  }
}