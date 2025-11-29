import 'package:flutter/material.dart';

class ImprintScreen extends StatelessWidget {
  const ImprintScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Impressum"),
        backgroundColor: Colors.pink,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Impressum (Demo)",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Dies ist ein Platzhalter für das Impressum.\n\n"
                "In der finalen Version müssen hier je nach Rechtslage "
                "u.a. folgende Angaben stehen:\n\n"
                "• Verantwortliche/r Betreiber/in der App\n"
                "• Anschrift\n"
                "• Kontakt (E-Mail, ggf. Telefon)\n"
                "• Vertretungsberechtigte Person(en)\n"
                "• Registereintrag (falls vorhanden)\n"
                "• Umsatzsteuer-ID (falls vorhanden)\n\n"
                "Die hier angezeigten Informationen dienen nur der "
                "Demonstration während der Prototyp-Phase.",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}