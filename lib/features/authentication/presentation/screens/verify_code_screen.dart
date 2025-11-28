import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const VerifyCodeScreen({
    required this.phoneNumber,
    required this.verificationId,
    Key? key,
  }) : super(key: key);

  @override
  _VerifyCodeScreenState createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  bool loading = false;

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) return;

    setState(() => loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // TODO: hier später auf Profil-Setup oder HomeScreen routen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/role-selection',
        (_) => false,
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ungültiger Code oder Fehler bei der Anmeldung")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Code eingeben"),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("SMS an: ${widget.phoneNumber}", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "6-stelliger Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Bestätigen"),
            ),
          ],
        ),
      ),
    );
  }
}