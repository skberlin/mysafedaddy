import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IdVerificationScreen extends StatefulWidget {
  final String inviteId;

  const IdVerificationScreen({
    Key? key,
    required this.inviteId,
  }) : super(key: key);

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  bool _loading = true;
  bool _notFound = false;
  bool _idPhotoTaken = false;
  bool _saving = false;

  String? _guestFirstName;
  String? _guestLastName;
  String? _guestBirthDate;

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
    setState(() {
      _guestFirstName = data['guestFirstName'] as String?;
      _guestLastName = data['guestLastName'] as String?;
      _guestBirthDate = data['guestBirthDate'] as String?;
      _loading = false;
    });
  }

  Future<void> _markIdVerified() async {
    setState(() {
      _saving = true;
    });

    try {
      final snap = await _inviteRef.get();
      final data = snap.data();
      final ownerUid = data != null ? data['ownerUid'] as String? : null;

      final updateData = {
        'idVerified': true,
        'idVerifiedAt': FieldValue.serverTimestamp(),
        // Einfaches Badge-Level:
        // 1 = Basisdaten, 2 = Basisdaten + Ausweis, 3 = optional später
        'badgeLevel': 2,
      };

      await _inviteRef.set(updateData, SetOptions(merge: true));

      if (ownerUid != null) {
        final userInviteRef = FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .collection('invites')
            .doc(widget.inviteId);

        await userInviteRef.set(updateData, SetOptions(merge: true));
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Ausweis-Prüfung gespeichert"),
          content: const Text(
            "Die Angaben aus dem Ausweis wurden bestätigt.\n"
            "Die Frau sieht jetzt einen höheren Vertrauens-Status.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Dialog
                Navigator.pop(context); // Screen
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Speichern: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
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
          title: const Text("Ausweis-Check"),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ausweis-Check"),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ausweis prüfen (Demo-KI)",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "In der finalen Version wird hier ein Foto deines Ausweises "
                "aufgenommen und per KI analysiert.\n\n"
                "Das Dokument selbst wird dabei NICHT dauerhaft gespeichert – "
                "es werden nur Name und Geburtsdatum extrahiert.",
              ),
              const SizedBox(height: 24),

              // Schritt 1: "Foto aufnehmen" (ohne echte Speicherung)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "1. Ausweis fotografieren",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "In dieser Demo-Version wird kein echtes Foto gespeichert.\n"
                      "Tippe einfach auf den Button, um die KI zu simulieren.",
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _idPhotoTaken = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                      ),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Ausweis-Foto aufnehmen (Simulation)"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Schritt 2: "KI-Ergebnis"
              if (_idPhotoTaken) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "2. KI-Auswertung",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Unsere Demo-KI hat folgende Daten aus deinem Ausweis "
                        "gelesen. Bitte überprüfe sie:",
                      ),
                      const SizedBox(height: 12),
                      _buildRow("Vorname", _guestFirstName ?? "-"),
                      _buildRow("Nachname", _guestLastName ?? "-"),
                      _buildRow(
                          "Geburtsdatum", _guestBirthDate?.isNotEmpty == true ? _guestBirthDate! : "nicht angegeben"),
                      const SizedBox(height: 16),
                      const Text(
                        "Wenn die Angaben korrekt sind, bestätige den Ausweis-Check.\n"
                        "Damit erhältst du einen höheren Vertrauensstatus "
                        "für dieses Treffen.",
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _markIdVerified,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified),
                        label: Text(
                          _saving
                              ? "Speichere..."
                              : "Angaben bestätigen (Ausweis-Check)",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}