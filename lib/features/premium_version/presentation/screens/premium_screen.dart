import 'package:flutter/material.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  void _showDemoInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Premium ist in dieser Demo-Version noch nicht aktiv.\n"
          "Später werden hier Abo-Modelle und echte Zahlungen integriert.",
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium"),
        backgroundColor: Colors.pink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mehr Sicherheit mit MySafeDaddy Premium",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "In der finalen Version kannst du mit Premium zusätzliche "
              "Sicherheitsfunktionen freischalten – z. B. unbegrenzte "
              "Notfallkontakte, SMS-Benachrichtigungen und erweiterte "
              "Ident-Prüfungen.",
            ),
            const SizedBox(height: 24),

            // Features-Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              color: Colors.pink.shade50,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Was Premium bringen soll",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _PremiumFeatureRow(
                      icon: Icons.group,
                      title: "Unbegrenzte Notfallkontakte",
                      subtitle:
                          "Hinterlege mehrere Vertrauenspersonen für SMS/E-Mail-Alarm.",
                    ),
                    SizedBox(height: 8),
                    _PremiumFeatureRow(
                      icon: Icons.sms,
                      title: "Automatische SMS-Alarmierung",
                      subtitle:
                          "Bei ausgelöstem Alarm werden deine Kontakte automatisch informiert "
                          "(in der Demo noch deaktiviert).",
                    ),
                    SizedBox(height: 8),
                    _PremiumFeatureRow(
                      icon: Icons.verified_user,
                      title: "Erweiterte Ident-Prüfung",
                      subtitle:
                          "Strengere Prüfung von Selfies und Ausweisen, um Fake-Profile zu erschweren.",
                    ),
                    SizedBox(height: 8),
                    _PremiumFeatureRow(
                      icon: Icons.support_agent,
                      title: "Priorisierter Support",
                      subtitle:
                          "Schnellere Hilfe bei Sicherheitsfragen und technischen Problemen.",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Preis-/Demo-Bereich
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Geplantes Modell (Beispiel)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "• Monatliches Abo (z. B. 4,99 €)\n"
                      "• Jederzeit kündbar\n"
                      "• Abrechnung über App Store / Play Store oder PayPal\n\n"
                      "Hinweis: Die Preise sind Platzhalter – für die finale "
                      "Version werden sie noch festgelegt.",
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showDemoInfo(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text("Premium testen (Demo-Hinweis)"),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text("Später entscheiden"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "Wichtig: Sicherheit zuerst",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Auch ohne Premium solltest du dein Treffen immer mit dem "
              "Sicherheitstimer und einem vertrauenswürdigen Notfallkontakt "
              "absichern. Premium soll diese Funktionen nur erweitern – "
              "nicht ersetzen.",
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumFeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PremiumFeatureRow({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.pink),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}