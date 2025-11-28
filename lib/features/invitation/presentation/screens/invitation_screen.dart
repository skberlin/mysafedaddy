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
          (_) => false,
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

  String _buildLink(String inviteId) {
    return "https://mysafedaddy.app/invite/$inviteId";
  }

  Future<void> _createInvite() async {
    if (_uid == null) return;

    final globalRef =
        FirebaseFirestore.instance.collection('invites').doc();

    final inviteId = globalRef.id;

    final data = {
      'ownerUid': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
      'verifiedBasic': false,
      'selfieVerified': false,
    };

    await globalRef.set(data);

    await _invitesRef().doc(inviteId).set(data);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Einladung erstellt: $inviteId"),
        duration: const Duration(seconds: 4),
      ),
    );
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _invitesRef()
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Noch keine Einladungen erstellt.\nTippe auf +",
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final inviteId = doc.id;
              final data = doc.data();

              final status = data['status'] ?? 'open';
              final guestFirstName = data['guestFirstName'];
              final guestLastName = data['guestLastName'];

              final guestName = (guestFirstName != null &&
                      guestFirstName.toString().isNotEmpty)
                  ? "$guestFirstName ${guestLastName ?? ''}"
                  : null;

              final verifiedBasic = data['verifiedBasic'] == true;
              final selfieVerified = data['selfieVerified'] == true;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Einladungscode:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    SelectableText(inviteId),

                    const SizedBox(height: 8),
                    const Text("Link:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SelectableText(
                      _buildLink(inviteId),
                      style:
                          const TextStyle(color: Colors.blueAccent, fontSize: 13),
                    ),

                    const SizedBox(height: 8),
                    Chip(label: Text("Status: $status")),

                    const SizedBox(height: 12),
                    guestName != null
                        ? Row(
                            children: [
                              const Icon(Icons.person),
                              const SizedBox(width: 6),
                              Text("Gast: $guestName"),
                            ],
                          )
                        : const Text("Gast hat Daten noch nicht ausgefüllt."),

                    const SizedBox(height: 8),

                    // ---------- STATUS BLOCK ----------
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              verifiedBasic
                                  ? Icons.verified
                                  : Icons.verified_outlined,
                              color:
                                  verifiedBasic ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              verifiedBasic
                                  ? "Ident-Status: Basisdaten bestätigt"
                                  : "Ident-Status: noch offen",
                              style: TextStyle(
                                color:
                                    verifiedBasic ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              selfieVerified
                                  ? Icons.face_retouching_natural
                                  : Icons.face,
                              color:
                                  selfieVerified ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              selfieVerified
                                  ? "Selfie: vorhanden"
                                  : "Selfie: noch ausstehend",
                              style: TextStyle(
                                color: selfieVerified
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/invite-guest',
                            arguments: inviteId,
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text("Als Gast testen"),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInvite,
        backgroundColor: Colors.pink,
        label: const Text("Einladung erstellen"),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}