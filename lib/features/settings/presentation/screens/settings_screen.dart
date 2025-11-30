import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _uid;
  bool _loading = true;

  bool _pushEnabled = true;
  bool _emailEnabled = true;

  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _uid = user?.uid;

    if (_uid == null) {
      Future.microtask(() {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/splash',
          (_) => false,
        );
      });
    } else {
      _loadSettings();
    }
  }

  DocumentReference<Map<String, dynamic>> _settingsDoc() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('meta')
        .doc('settings');
  }

  Future<void> _loadSettings() async {
    if (_uid == null) return;

    try {
      final snap = await _settingsDoc().get();
      if (snap.exists) {
        final data = snap.data()!;
        setState(() {
          _pushEnabled = (data['pushEnabled'] ?? true) as bool;
          _emailEnabled = (data['emailEnabled'] ?? true) as bool;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateSettings({bool? push, bool? email}) async {
    if (_uid == null) return;

    final newPush = push ?? _pushEnabled;
    final newEmail = email ?? _emailEnabled;

    setState(() {
      _pushEnabled = newPush;
      _emailEnabled = newEmail;
    });

    try {
      await _settingsDoc().set(
        {
          'pushEnabled': newPush,
          'emailEnabled': newEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Fehler beim Speichern der Settings: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Account löschen'),
            content: const Text(
              'Möchtest du deinen Account wirklich löschen?\n\n'
              'In dieser Demo-Version wird dein Account als '
              '„zur Löschung vorgemerkt“ markiert und du wirst abgemeldet.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Ja, löschen',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_uid == null) return;

    setState(() {
      _deletingAccount = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).set(
        {
          'markedForDeletion': true,
          'markedForDeletionAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final user = FirebaseAuth.instance.currentUser;
      try {
        await user?.delete();
      } catch (e) {
        debugPrint('FirebaseAuth-Delete fehlgeschlagen (Demo): $e');
      }

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/splash',
        (_) => false,
      );
    } catch (e) {
      debugPrint('Fehler beim Account-Löschen: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Löschen: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingAccount = false;
        });
      }
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null || _loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: Colors.pink,
      ),
      body: ListView(
        children: [
          // -------- Allgemein --------
          _sectionHeader('Allgemein'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Passwort & Sicherheit'),
            subtitle: const Text('Anmelde- und Sicherheitsoptionen'),
            onTap: () {
              // Hier später auf echten Security-Screen routen
              showDialog(
                context: context,
                builder: (ctx) => const AlertDialog(
                  title: Text('Passwort & Sicherheit'),
                  content: Text(
                    'In dieser Demo-Version ist dieser Bereich noch nicht aktiv.\n'
                    'Später kannst du hier Passwort, 2FA und Sicherheitsoptionen verwalten.',
                  ),
                ),
              );
            },
          ),

          // -------- Rechtliches --------
          _sectionHeader('Rechtliches'),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('AGB'),
            subtitle: const Text('Allgemeine Geschäftsbedingungen'),
            onTap: () {
              Navigator.pushNamed(context, '/legal-terms');
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Datenschutz'),
            subtitle: const Text('Informationen zum Umgang mit Daten'),
            onTap: () {
              Navigator.pushNamed(context, '/privacy-policy');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Impressum'),
            onTap: () {
              Navigator.pushNamed(context, '/imprint');
            },
          ),

          // -------- Benachrichtigungen --------
          _sectionHeader('Benachrichtigungen'),
          SwitchListTile(
            title: const Text('Push-Benachrichtigungen'),
            subtitle: const Text('Alarm- und Sicherheitsmeldungen'),
            value: _pushEnabled,
            onChanged: (value) => _updateSettings(push: value),
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          SwitchListTile(
            title: const Text('E-Mail-Benachrichtigungen'),
            subtitle: const Text('Zusätzliche Erinnerungen und Infos'),
            value: _emailEnabled,
            onChanged: (value) => _updateSettings(email: value),
            secondary: const Icon(Icons.email_outlined),
          ),

          const SizedBox(height: 24),

          // -------- Account löschen --------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _deletingAccount ? null : _confirmDeleteAccount,
              icon: _deletingAccount
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_forever),
              label: Text(
                _deletingAccount ? 'Lösche Account…' : 'Account löschen',
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              'Hinweis: Dies ist eine Demo-Version von MySafeDaddy. '
              'Funktionen wie SMS-Benachrichtigungen, Ausweis-KI und '
              'Premium-Abos sind noch nicht produktiv aktiv.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}