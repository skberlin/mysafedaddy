import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InvitationScreen extends StatefulWidget {
  const InvitationScreen({Key? key}) : super(key: key);

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) {
      Future.microtask(() {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/splash',
          (route) => false,
        );
      });
    }
  }

  CollectionReference<Map<String, dynamic>> _invitesRef() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('invites');
  }

  Future<void> _createInvite() async {
    if (_uid == null) return;

    final docRef = await _invitesRef().add({
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open', // open / used / cancelled
    });

    final inviteId = docRef.id;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Einladung erstellt. Teile diesen Code mit dem Mann:\n$inviteId",
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _buildLink(String inviteId) {
    // Platzhalter-Link – später durch echten Deep-Link / Domain ersetzen
    return "https://mysafedaddy.app/invite/$inviteId";
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Einladungen"),
        backgroundColor: Colors.pink,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Erstelle eine Einladung für dein nächstes Treffen.\n"
              "Der Mann erhält einen Code/Link, um sich zu identifizieren und "
              "ein Foto hochzuladen (wird in einem späteren Schritt ergänzt).",
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _invitesRef()
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Du hast noch keine Einladungen erstellt.\n"
                      "Tippe auf das +, um eine Einladung zu erzeugen.",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final inviteId = doc.id;
                    final status = data['status'] ?? 'open';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final createdDate = createdAt?.toDate();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Einladungscode:",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            inviteId,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Link:",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _buildLink(inviteId),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                label: Text("Status: $status"),
                              ),
                              const SizedBox(width: 8),
                              if (createdDate != null)
                                Text(
                                  "Erstellt: ${createdDate.toLocal()}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.pink,
          onPressed: _createInvite,
          icon: const Icon(Icons.add),
          label: const Text("Einladung erstellen"),
        ),
      ),
    );
  }
}