import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'alarm_detail_screen.dart';

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
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _alarmsStream() {
    if (_uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('alarms')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return "";
    final dt = ts.toDate();
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$dd.$mm.$yyyy $hh:$min";
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hier siehst du alle Alarme, die durch den Sicherheitstimer ausgelöst wurden.",
            ),
            const SizedBox(height: 8),
            const Text(
              "In dieser Demo-Version werden nur Daten in Firestore gespeichert – "
              "in der finalen Version würden hier die echten Benachrichtigungen (SMS/E-Mail) "
              "geloggt werden.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _alarmsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Bisher wurden noch keine Alarme ausgelöst.\n\n"
                          "Starte ein Treffen und lass den Sicherheitstimer testweise ablaufen, "
                          "um einen Demo-Alarm zu erzeugen.",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final status = (data['status'] as String?) ?? 'open';
                      final createdAt = data['createdAt'] as Timestamp?;
                      final source = (data['source'] as String?) ?? 'timer_expired';
                      final lat = (data['locationLat'] as num?)?.toDouble();
                      final lng = (data['locationLng'] as num?)?.toDouble();

                      final isOpen = status == 'open';
                      final isResolved = status == 'resolved';

                      Color statusColor;
                      String statusText;
                      IconData statusIcon;

                      if (isResolved) {
                        statusColor = Colors.green;
                        statusText = "Gelöst (Demo)";
                        statusIcon = Icons.check_circle;
                      } else if (isOpen) {
                        statusColor = Colors.red;
                        statusText = "Offen (Demo)";
                        statusIcon = Icons.warning_amber_rounded;
                      } else {
                        statusColor = Colors.orange;
                        statusText = status;
                        statusIcon = Icons.info_outline;
                      }

                      final locationText =
                          (lat != null && lng != null)
                              ? "Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}"
                              : "Letzter Standort: nicht verfügbar";

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AlarmDetailScreen(
                                  alarmId: doc.id,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(statusIcon, color: statusColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(createdAt),
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
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Hinweis: Benachrichtigungen sind aktuell nur als Demo implementiert "
                                  "(es wird noch keine echte SMS/E-Mail versendet). "
                                  "Tippe auf die Karte, um alle Details zu sehen.",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}