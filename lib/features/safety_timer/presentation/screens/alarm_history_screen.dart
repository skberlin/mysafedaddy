import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AlarmHistoryScreen extends StatefulWidget {
  const AlarmHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AlarmHistoryScreen> createState() => _AlarmHistoryScreenState();
}

class _AlarmHistoryScreenState extends State<AlarmHistoryScreen> {
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) {
      Future.microtask(() {
        Navigator.pushNamedAndRemoveUntil(context, '/splash', (_) => false);
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _alarmStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('alarms')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'Unbekannt';
    final dt = ts.toDate();
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _statusText(String status) {
    switch (status) {
      case 'open':
        return 'Offen (Demo)';
      case 'notified':
        return 'Notfallkontakte informiert (Demo)';
      case 'resolved':
        return 'Entwarnung / erledigt';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.red;
      case 'notified':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alarm-Historie"),
        backgroundColor: Colors.pink,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: const Text(
              "Hier siehst du alle Alarme, die durch den Sicherheitstimer "
              "ausgelöst wurden.\n\n"
              "In dieser Demo-Version werden nur Daten in Firestore "
              "gespeichert – in der finalen Version würden hier die echten "
              "Benachrichtigungen (SMS/E-Mail) geloggt werden.",
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _alarmStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Fehler beim Laden der Alarme:\n${snapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "Bisher wurden noch keine Alarme ausgelöst.\n\n"
                        "Starte ein Treffen und lass den Sicherheitstimer "
                        "testweise ablaufen, um einen Demo-Alarm zu erzeugen.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final createdAt =
                        _formatTimestamp(data['createdAt'] as Timestamp?);
                    final status = (data['status'] as String? ?? 'open');
                    final inviteId = data['inviteId'] as String?;
                    final source = data['source'] as String? ?? 'unbekannt';
                    final lat = (data['locationLat'] as num?)?.toDouble();
                    final lng = (data['locationLng'] as num?)?.toDouble();

                    String locationText;
                    if (lat != null && lng != null) {
                      locationText =
                          "Letzter Standort: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}";
                    } else {
                      locationText = "Letzter Standort: nicht verfügbar";
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: _statusColor(status),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _statusText(status),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _statusColor(status),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                createdAt,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Quelle: $source",
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            locationText,
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (inviteId != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              "Treffen-Code: $inviteId",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Text(
                            "Hinweis: Benachrichtigungen sind aktuell nur als Demo "
                            "implementiert (es wird noch keine echte SMS/E-Mail "
                            "versendet).",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}