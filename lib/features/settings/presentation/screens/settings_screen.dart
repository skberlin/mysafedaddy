import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Einstellungen"),
        backgroundColor: Colors.pink,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Allgemein",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Sprache / Region"),
            subtitle: const Text("Aktuell: Deutsch (Demo)"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Sprach-Einstellungen werden in einer späteren Version ergänzt.",
                  ),
                ),
              );
            },
          ),
          const Divider(height: 24),

          const Text(
            "Rechtliches",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text("AGB"),
            subtitle: const Text("Allgemeine Geschäftsbedingungen"),
            onTap: () {
              Navigator.pushNamed(context, '/legal-terms');
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text("Datenschutz"),
            subtitle: const Text("Informationen zum Umgang mit Daten"),
            onTap: () {
              Navigator.pushNamed(context, '/privacy-policy');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Impressum"),
            onTap: () {
              Navigator.pushNamed(context, '/imprint');
            },
          ),
          const Divider(height: 24),

          const Text(
            "App-Informationen",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.phone_iphone),
            title: const Text("App-Version"),
            subtitle: const Text("Demo-Version • Build 0.1.0"),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const Text(
            "Hinweis: Diese Version von MySafeDaddy ist ein Prototyp. "
            "Funktionen wie SMS-Benachrichtigungen, Ausweis-KI und "
            "Premium-Abos sind noch nicht produktiv aktiv.",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}