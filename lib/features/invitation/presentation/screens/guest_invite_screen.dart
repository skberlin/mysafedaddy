import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GuestInviteScreen extends StatefulWidget {
  final String inviteId;

  const GuestInviteScreen({
    Key? key,
    required this.inviteId,
  }) : super(key: key);

  @override
  State<GuestInviteScreen> createState() => _GuestInviteScreenState();
}

class _GuestInviteScreenState extends State<GuestInviteScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  bool _loading = true;
  bool _notFound = false;
  bool _usedOrClosed = false;

  late DocumentReference<Map<String, dynamic>> _inviteRef;

  @override
  void initState() {
    super.initState();
    _inviteRef =
        FirebaseFirestore.instance.collection('invites').doc(widget.inviteId);
    _loadInvite();
  }

  Future<void> _loadInvite() async {
    final snap = await _inviteRef.get();
    if (!snap.exists) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }

    final data = snap.data()!;
    final status = data['status'] ?? 'open';

    setState(() {
      _loading = false;
      _usedOrClosed = status != 'open';
    });
  }

  Future<void> _submitBasicVerification() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final birthDate = _birthDateController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bitte Vor- und Nachnamen eingeben."),
        ),
      );
      return;
    }

    try {
      final snap = await _inviteRef.get();
      if (!snap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Einladung existiert nicht mehr."),
          ),
        );
        return;
      }

      final data = snap.data()!;
      final ownerUid = data['ownerUid'] as String?;

      final updateData = {
        'guestFirstName': firstName,
        'guestLastName': lastName,
        'guestBirthDate': birthDate,
        'verifiedBasic': true,
        'status': 'used',
        'verifiedAt': FieldValue.serverTimestamp(),
      };

      // global speichern
      await _inviteRef.set(updateData, SetOptions(merge: true));

      // spiegeln bei der Frau
      if (ownerUid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .collection('invites')
            .doc(widget.inviteId)
            .set(updateData, SetOptions(merge: true));
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Vielen Dank"),
          content: const Text(
            "Deine Basisdaten wurden übermittelt.\n"
            "Als nächstes kannst du ein Selfie aufnehmen, "
            "damit die Frau weiß, wer du bist.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Fehler beim Speichern der Daten: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFound) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Einladung"),
          backgroundColor: Colors.pink,
        ),
        body: const Center(
          child: Text(
            "Diese Einladung konnte nicht gefunden werden.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_usedOrClosed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Einladung"),
          backgroundColor: Colors.pink,
        ),
        body: const Center(
          child: Text(
            "Diese Einladung wurde bereits verwendet oder ist nicht mehr aktiv.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ident-Check"),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Willkommen!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Bitte gib deine Basisdaten ein, damit die Frau weiß, "
                "wer du bist.",
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: "Vorname",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: "Nachname",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _birthDateController,
                decoration: const InputDecoration(
                  labelText: "Geburtsdatum (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitBasicVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Daten übermitteln"),
              ),

              const SizedBox(height: 24),

              // ---------- SELFIE BUTTON ----------
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/selfie-capture',
                    arguments: widget.inviteId,
                  );
                },
                icon: const Icon(Icons.camera_alt),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                label: const Text("Selfie aufnehmen"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}