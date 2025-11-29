import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Datenschutz"),
        backgroundColor: Colors.pink,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Datenschutzerklärung (Demo)",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Hinweis: Dies ist ein Platzhalter für die spätere "
                "Datenschutzerklärung von MySafeDaddy.\n\n"
                "In der finalen Version werden hier u.a. folgende Punkte "
                "geregelt:\n"
                "• Welche personenbezogenen Daten verarbeitet werden "
                "(z.B. Telefonnummer, Profilangaben, Standort während eines Treffens)\n"
                "• Zu welchen Zwecken die Daten genutzt werden "
                "(z.B. Sicherheitsfunktionen, Missbrauchserkennung)\n"
                "• Rechtsgrundlagen der Verarbeitung\n"
                "• Speicherdauer und Löschkonzepte\n"
                "• Weitergabe an Dienstleister (z.B. SMS- oder E-Mail-Provider)\n"
                "• Rechte der Nutzerinnen und Nutzer (Auskunft, Löschung, etc.)\n"
                "• Kontaktmöglichkeiten für Datenschutz-Anfragen\n\n"
                "Diese Demo-Fassung dient nur dazu, die Struktur der App "
                "zu zeigen. Sie ersetzt keine echte Datenschutzerklärung.",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}