import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ⬇️ neu: direkter Import des Einladungs-Screens
import 'package:mysafedaddy/features/invitation/presentation/screens/invitation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _uid;
  String? _firstName;
  String? _lastName;
  String? _phoneNumber;

  bool _loadingProfile = true;
  bool _sharingInvite = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _uid = user?.uid;
    _phoneNumber = user?.phoneNumber;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_uid == null) {
      setState(() {
        _loadingProfile = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _firstName = data['firstName'] as String?;
          _lastName = data['lastName'] as String?;
        });
      }
    } catch (e) {
      // Nur loggen, UI bleibt nutzbar
      debugPrint("Fehler beim Laden des Profils: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
    }
  }

  /// 1. Vorname + Nachname
  /// 2. nur Vorname
  /// 3. Telefonnummer
  /// 4. Fallback: "Nutzerin"
  String _buildDisplayName() {
    if (_firstName != null && _firstName!.trim().isNotEmpty) {
      final last = (_lastName ?? "").trim();
      if (last.isNotEmpty) {
        return "${_firstName!.trim()} $last";
      }
      return _firstName!.trim();
    }

    if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
      return _phoneNumber!;
    }

    return "Nutzerin";
  }

  /// Share-Button:
  /// Sucht die letzte Einladung und kopiert den Link in die Zwischenablage.
  Future<void> _shareLatestInvite() async {
    if (_uid == null) return;

    setState(() {
      _sharingInvite = true;
    });

    try {
      final invitesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('invites')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (invitesSnap.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Du hast noch keine Einladung erstellt. "
              "Erstelle zuerst unter „Mann einladen“ einen Einladungslink.",
            ),
          ),
        );
        return;
      }

      final inviteData = invitesSnap.docs.first.data();

      final code = (inviteData['code'] ??
              inviteData['inviteCode'] ??
              inviteData['id'] ??
              "")
          .toString()
          .trim();

      String? link;
      if (inviteData['inviteLink'] != null &&
          (inviteData['inviteLink'] as String).isNotEmpty) {
        link = inviteData['inviteLink'] as String;
      } else if (code.isNotEmpty) {
        link = "https://mysafedaddy.app/invite/$code";
      }

      if (link == null || link.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Es konnte kein Einladungslink gefunden werden. "
              "Bitte erstelle eine neue Einladung.",
            ),
          ),
        );
        return;
      }

      await Clipboard.setData(ClipboardData(text: link));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Einladungslink kopiert:\n$link"),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Fehler beim Vorbereiten des Einladungslinks: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sharingInvite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _buildDisplayName();

    return Scaffold(
      appBar: AppBar(
  backgroundColor: Colors.pink,
  title: const Text("MySafeDaddy"),
  actions: [
    IconButton(
      tooltip:
          "Letzten Einladungslink teilen (Demo: kopiert in Zwischenablage)",
      onPressed: _sharingInvite ? null : _shareLatestInvite,
      icon: _sharingInvite
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.share),
    ),
    IconButton(
      tooltip: "Einstellungen",
      onPressed: () {
        Navigator.pushNamed(context, '/settings');
      },
      icon: const Icon(Icons.settings),
    ),
  ],
),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loadingProfile
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Willkommen, $displayName",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Rolle: Frau",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_phoneNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _phoneNumber!,
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

                  // Aktionen
                  _HomeActionCard(
                    icon: Icons.timer,
                    title: "Timer starten",
                    subtitle: "Sicherheitstimer für ein Treffen",
                    onTap: () {
                      Navigator.pushNamed(context, '/safety-timer');
                    },
                  ),

                  _HomeActionCard(
                    icon: Icons.person_add,
                    title: "Mann einladen",
                    subtitle: "Einladungslink & Ident-Check vorbereiten",
                    onTap: () {
                      // ⬇️ zurück zur funktionierenden Variante:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InvitationScreen(),
                        ),
                      );
                    },
                  ),

                  _HomeActionCard(
                    icon: Icons.group,
                    title: "Notfallkontakte",
                    subtitle: "Vertrauenspersonen hinterlegen",
                    onTap: () {
                      Navigator.pushNamed(context, '/emergency-contacts');
                    },
                  ),
                  _HomeActionCard(
                    icon: Icons.history,
                    title: "Alarm-Historie",
                    subtitle:
                        "Alle ausgelösten Alarme aus dem Sicherheitstimer",
                    onTap: () {
                      Navigator.pushNamed(context, '/alarm-history');
                    },
                  ),
                  _HomeActionCard(
                    icon: Icons.star,
                    title: "Premium",
                    subtitle: "Unbegrenzte Kontakte & SMS-Alarm",
                    onTap: () {
                      Navigator.pushNamed(context, '/premium');
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeActionCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.pink),
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
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
}