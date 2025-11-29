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
      'status': 'open', // open | used | revoked
      'verifiedBasic': false,
      'selfiePresent': false,
      'selfieVerified': false,
      'idVerified': false,
      'badgeLevel': 0,
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

  Future<void> _revokeInvite(String inviteId) async {
    if (_uid == null) return;

    try {
      final update = {
        'status': 'revoked',
        'revokedAt': FieldValue.serverTimestamp(),
      };

      // globales Invite-Dokument aktualisieren
      await FirebaseFirestore.instance
          .collection('invites')
          .doc(inviteId)
          .set(update, SetOptions(merge: true));

      // gespiegelt bei der Frau aktualisieren
      await _invitesRef()
          .doc(inviteId)
          .set(update, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Einladung wurde zurückgezogen."),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Fehler beim Zurückziehen: $e"),
        ),
      );
    }
  }

  Future<void> _confirmRevoke(String inviteId) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Einladung zurückziehen"),
            content: const Text(
              "Möchtest du diese Einladung wirklich zurückziehen?\n\n"
              "Der Gast kann den Code danach nicht mehr nutzen.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Abbrechen"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Zurückziehen",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await _revokeInvite(inviteId);
    }
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
            padding: const EdgeInsets.only(bottom: 100, top: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final inviteId = doc.id;
              final data = doc.data();

              final status = (data['status'] ?? 'open') as String;
              final guestFirstName = data['guestFirstName'];
              final guestLastName = data['guestLastName'];
              final guestName = (guestFirstName != null &&
                      guestFirstName.toString().isNotEmpty)
                  ? "$guestFirstName ${guestLastName ?? ''}"
                  : null;

              final verifiedBasic = data['verifiedBasic'] == true;
              final selfiePresent = data['selfiePresent'] == true;
              final selfieVerified = data['selfieVerified'] == true;
              final idVerified = data['idVerified'] == true;
              final badgeLevel = (data['badgeLevel'] ?? 0) as int;

              Color statusColor;
              switch (status) {
                case 'used':
                  statusColor = Colors.blueGrey;
                  break;
                case 'revoked':
                  statusColor = Colors.redAccent;
                  break;
                default:
                  statusColor = Colors.green;
              }

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
                    const Text(
                      "Einladungscode:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(inviteId),

                    const SizedBox(height: 8),
                    const Text(
                      "Link:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SelectableText(
                      _buildLink(inviteId),
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Chip(
                      label: Text("Status: $status"),
                      backgroundColor: statusColor.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 12),
                    guestName != null
                        ? Row(
                            children: [
                              const Icon(Icons.person),
                              const SizedBox(width: 6),
                              Text("Gast: $guestName"),
                            ],
                          )
                        : const Text(
                            "Gast hat Daten noch nicht ausgefüllt.",
                            style:
                                TextStyle(fontSize: 13, color: Colors.grey),
                          ),

                    const SizedBox(height: 8),

                    // ---------- STATUS / BADGE ----------
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
                                color: verifiedBasic
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              selfieVerified || selfiePresent
                                  ? Icons.face_retouching_natural
                                  : Icons.face,
                              color: (selfieVerified || selfiePresent)
                                  ? Colors.green
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (selfieVerified || selfiePresent)
                                  ? "Selfie: vorhanden"
                                  : "Selfie: noch ausstehend",
                              style: TextStyle(
                                color: (selfieVerified || selfiePresent)
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              idVerified ? Icons.badge : Icons.badge_outlined,
                              color:
                                  idVerified ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              idVerified
                                  ? "Ausweis-Check: bestätigt"
                                  : "Ausweis-Check: noch offen",
                              style: TextStyle(
                                color:
                                    idVerified ? Colors.green : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.shield, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              "Trust-Level: $badgeLevel / 3",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ---------- ACTION BUTTONS ----------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (status != 'revoked')
                            TextButton.icon(
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
                          TextButton.icon(
                            onPressed: status == 'revoked'
                                ? null
                                : () => _confirmRevoke(inviteId),
                            icon: Icon(
                              Icons.cancel,
                              color: status == 'revoked'
                                  ? Colors.grey
                                  : Colors.redAccent,
                            ),
                            label: Text(
                              status == 'revoked'
                                  ? "Zurückgezogen"
                                  : "Einladung zurückziehen",
                              style: TextStyle(
                                color: status == 'revoked'
                                    ? Colors.grey
                                    : Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
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