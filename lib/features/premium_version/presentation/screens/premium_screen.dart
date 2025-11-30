import 'package:flutter/material.dart';
import '../../../premium_version/data/premium_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _service = PremiumService();

  bool _loading = true;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await _service.getPremiumStatus();
    setState(() {
      _active = status["active"] == true;
      _loading = false;
    });
  }

  Future<void> _activatePremium() async {
    await _service.activatePremiumDemo();
    await _loadStatus();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Premium aktiviert (Demo)."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.pink.shade300, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _active
                          ? "Dein Premium ist aktiv"
                          : "Premium freischalten",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Vorteile von Premium",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _benefit(Icons.sms, "SMS-Notfallkontakte freigeschaltet"),
            _benefit(Icons.location_on, "Live-Treffen-Tracking ohne Limit"),
            _benefit(Icons.person_add_alt, "Unbegrenzte Einladungen"),
            _benefit(Icons.verified_user, "Schnellere Ident-Verifikation"),
            _benefit(Icons.shield, "Premium-Sicherheitslevel"),

            const SizedBox(height: 30),

            // PREIS (Demo)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Premium (Demo)", style: TextStyle(fontSize: 16)),
                      Text(
                        "Später Abo-Modell: z. B. 4,99€/Monat",
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (!_active)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _activatePremium,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Premium aktivieren (Demo)",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

            if (_active)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text("Premium aktiv"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.pink.shade300),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}