import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUserProfile();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Future.microtask(() {
        Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
      });
      return FirebaseFirestore.instance.collection('users').doc('dummy').get();
    }

    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MySafeDaddy"),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Kein Profil gefunden. Bitte App neu starten."),
            );
          }

          final data = snapshot.data!.data()!;
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          final phone = data['phoneNumber'] ?? '';
          final role = data['role'] ?? 'woman';
          final isWoman = role == 'woman';

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Willkommen, $firstName $lastName",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(isWoman ? "Rolle: Frau" : "Rolle: Mann"),
                        backgroundColor: Colors.pink.shade50,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(phone),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Was möchtest du tun?",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  _HomeActionButton(
                    icon: Icons.timer,
                    title: "Timer starten",
                    subtitle: "Sicherheitstimer für ein Treffen",
                    onTap: () {
                      Navigator.pushNamed(context, '/safety-timer');
                    },
                  ),

                  const SizedBox(height: 12),

                  // NEU: Einladung für Mann
                  _HomeActionButton(
                    icon: Icons.person_add,
                    title: "Mann einladen",
                    subtitle: "Einladungslink & Ident-Check vorbereiten",
                    onTap: () {
                      Navigator.pushNamed(context, '/invitation');
                    },
                  ),

                  const SizedBox(height: 12),

                  _HomeActionButton(
                    icon: Icons.contact_phone,
                    title: "Notfallkontakte",
                    subtitle: "Vertrauenspersonen hinterlegen",
                    onTap: () {
                      Navigator.pushNamed(context, '/emergency-contacts');
                    },
                  ),

                  const SizedBox(height: 12),

                  _HomeActionButton(
                    icon: Icons.star,
                    title: "Premium",
                    subtitle: "Unbegrenzte Kontakte & SMS-Alarm",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Premium-Modell wird später integriert."),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeActionButton({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade100,
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.pink),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}