import 'package:flutter/material.dart';

class LegalTermsScreen extends StatelessWidget {
  const LegalTermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AGB"),
        backgroundColor: Colors.pink,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Allgemeine Geschäftsbedingungen (Demo)",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Hinweis: Dies ist ein Platzhaltertext für die AGB. "
                "In der finalen Version werden hier die rechtlich "
                "gültigen Vertragsbedingungen für die Nutzung von "
                "MySafeDaddy eingefügt.\n\n"
                "Beispiele, die später enthalten sein können:\n"
                "• Geltungsbereich und Vertragspartner\n"
                "• Leistungsbeschreibung (Sicherheitsfunktionen, Matching, etc.)\n"
                "• Nutzungsrechte und -pflichten\n"
                "• Haftungsbeschränkungen\n"
                "• Kündigung und Sperrung von Accounts\n"
                "• Zahlungsbedingungen (für Premium-Funktionen)\n"
                "• Informationen zum Widerrufsrecht (falls relevant)\n\n"
                "Bis zur finalen rechtlichen Ausarbeitung dienen diese "
                "Angaben ausschließlich zur Demonstration des App-Aufbaus.",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}