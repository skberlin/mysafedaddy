import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late final String? _uid;
  final bool _isPremium = false; // später aus Firestore/Subscription laden

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) {
      // Wenn kein User eingeloggt ist, zurück zum Splash
      Future.microtask(() {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/splash',
          (route) => false,
        );
      });
    }
  }

  CollectionReference<Map<String, dynamic>> _contactsRef() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('emergencyContacts');
  }

  Future<void> _addContact() async {
    if (_uid == null) return;

    // Erst Anzahl prüfen (Free: max 1 Kontakt)
    final snapshot = await _contactsRef().get();
    final count = snapshot.docs.length;

    if (!_isPremium && count >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "In der kostenlosen Version kannst du nur einen Notfallkontakt speichern.\n"
            "Für mehr Kontakte wird später Premium benötigt.",
          ),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Notfallkontakt hinzufügen"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "E-Mail",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Telefon (optional)",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Abbrechen"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final phone = phoneController.text.trim();

                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "Bitte mindestens Name und E-Mail angeben."),
                    ),
                  );
                  return;
                }

                await _contactsRef().add({
                  'name': name,
                  'email': email,
                  'phone': phone,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (mounted) Navigator.pop(ctx);
              },
              child: const Text("Speichern"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteContact(String id) async {
    if (_uid == null) return;
    await _contactsRef().doc(id).delete();
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
        title: const Text("Notfallkontakte"),
        backgroundColor: Colors.pink,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _contactsRef()
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Du hast noch keine Notfallkontakte.\n"
                "Füge eine vertrauenswürdige Person hinzu.",
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            // unten extra Platz, damit nichts mit dem FAB kollidiert
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final phone = data['phone'] ?? '';

              return Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Kontakt löschen?"),
                          content: Text(
                              "Möchtest du den Kontakt \"$name\" wirklich entfernen?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Abbrechen"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Löschen"),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) => _deleteContact(doc.id),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person, color: Colors.pink),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // FAB zentriert und etwas höher, damit er nicht vom reCAPTCHA-Badge überdeckt wird
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          backgroundColor: Colors.pink,
          onPressed: _addContact,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}