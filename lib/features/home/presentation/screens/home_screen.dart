import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _uid;
  String? _displayName;
  String? _role;
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    if (!snap.exists) return;
    final data = snap.data()!;
    setState(() {
      _displayName = data['displayName'] as String? ?? 'Nutzerin';
      _role = data['role'] as String? ?? 'woman';
      _phoneNumber = data['phoneNumber'] as String?;
    });
  }

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _displayName ?? 'Nutzerin';
    final phone = _phoneNumber ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("MySafeDaddy"),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            onPressed: () {
              // später: Sharing des Einladungslinks / App-Link
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Willkommen, $name",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Rolle: ${_role == 'man' ? 'Mann' : 'Frau'}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                if (phone.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      phone,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Was möchtest du tun?",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildMenuCard(
                    icon: Icons.timer,
                    iconColor: Colors.pink,
                    title: "Timer starten",
                    subtitle: "Sicherheitstimer für ein Treffen",
                    onTap: () {
                      Navigator.pushNamed(context, '/safety-timer');
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.person_add_alt_1,
                    iconColor: Colors.pink,
                    title: "Mann einladen",
                    subtitle: "Einladungslink & Ident-Check vorbereiten",
                    onTap: () {
                      Navigator.pushNamed(context, '/invitation');
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.contact_emergency,
                    iconColor: Colors.deepPurple,
                    title: "Notfallkontakte",
                    subtitle: "Vertrauenspersonen hinterlegen",
                    onTap: () {
                      Navigator.pushNamed(context, '/emergency-contacts');
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.history,
                    iconColor: Colors.orange,
                    title: "Alarm-Historie",
                    subtitle:
                        "Alle ausgelösten Alarme aus dem Sicherheitstimer",
                    onTap: () {
                      Navigator.pushNamed(context, '/alarm-history');
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.star,
                    iconColor: Colors.pink,
                    title: "Premium",
                    subtitle: "Unbegrenzte Kontakte & SMS-Alarm",
                    onTap: () {
                      // später: Premium-/Paywall-Screen
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}