import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AlarmDetailScreen extends StatefulWidget {
  final String alarmId;

  const AlarmDetailScreen({
    Key? key,
    required this.alarmId,
  }) : super(key: key);

  @override
  State<AlarmDetailScreen> createState() => _AlarmDetailScreenState();
}

class _AlarmDetailScreenState extends State<AlarmDetailScreen> {
  String? _uid;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  DocumentReference<Map<String, dynamic>>? _alarmRef() {
    if (_uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('alarms')
        .doc(widget.alarmId);
  }

  Future<void> _markResolved() async {
    final ref = _alarmRef();
    if (ref == null) return;

    setState(() {
      _updating = true;
    });

    try {
      await ref.set(
        {
          'status': 'resolved',
          'resolvedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Alarm als gelöst markiert (Demo)."),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Fehler beim Aktualisieren des Alarms: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return "-";
    final dt = ts.toDate();
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$dd.$mm.$yyyy, $hh:$min Uhr";
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ref = _alarmRef()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alarm-Details"),
        backgroundColor: Colors.pink,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Alarm nicht gefunden."),
            );
          }

          final data = snapshot.data!.data()!;
          final status = (data['status'] as String?) ?? 'open';
          final source = (data['source'] as String?) ?? 'timer_expired';
          final createdAt = data['createdAt'] as Timestamp?;
          final resolvedAt = data['resolvedAt'] as Timestamp?;
          final inviteId = data['inviteId'] as String?;
          final timerId = data['timerId'] as String?;
          final lat = (data['locationLat'] as num?)?.toDouble();
          final lng = (data['locationLng'] as num?)?.toDouble();
          final meetingStatus = data['meetingStatusAtAlarm'] as String?;

          final isResolved = status == 'resolved';
          final isOpen = status == 'open';

          Color statusColor;
          String statusLabel;
          if (isResolved) {
            statusColor = Colors.green;
            statusLabel = "Gelöst";
          } else if (isOpen) {
            statusColor = Colors.red;
            statusLabel = "Offen (Demo)";
          } else {
            statusColor = Colors.orange;
            statusLabel = status;
          }

          final mapLink = (lat != null && lng != null)
              ? "https://www.google.com/maps/search/?api=1&query=$lat,$lng"
              : null;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status-Badge
                Row(
                  children: [
                    Icon(
                      isResolved ? Icons.check_circle : Icons.warning,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Dieser Alarm wurde durch den Sicherheitstimer "
                  "deines Treffens ausgelöst.",
                ),
                const SizedBox(height: 24),

                // Basisdaten
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Allgemeine Informationen",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow(
                          "Alarm ausgelöst",
                          _formatTimestamp(createdAt),
                        ),
                        _infoRow(
                          "Alarm-Quelle",
                          source,
                        ),
                        if (inviteId != null)
                          _infoRow("Treffen-Code", inviteId),
                        if (timerId != null)
                          _infoRow("Timer-ID", timerId),
                        if (meetingStatus != null)
                          _infoRow("Treffen-Status beim Alarm", meetingStatus),
                        if (isResolved)
                          _infoRow(
                            "Als gelöst markiert",
                            _formatTimestamp(resolvedAt),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Standort
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Standort beim Alarm",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (lat != null && lng != null) ...[
                          _infoRow("Latitude", lat.toStringAsFixed(5)),
                          _infoRow("Longitude", lng.toStringAsFixed(5)),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              if (mapLink != null) {
                                // Für Web/Desktop reicht Launch über Browser.
                                // In Mobile-Apps würde man url_launcher verwenden.
                                // Hier nur Demo-Hinweis:
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Kartenlink (Demo): $mapLink",
                                    ),
                                    duration:
                                        const Duration(seconds: 4),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.map),
                            label: const Text("Kartenlink anzeigen (Demo)"),
                          ),
                        ] else
                          const Text(
                            "Kein Standort gespeichert.\n"
                            "In der finalen Version würde hier die "
                            "letzte bekannte Position stehen.",
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Demo-Hinweis
                const Text(
                  "Hinweis: In dieser Demo-Version werden keine echten "
                  "Benachrichtigungen verschickt. "
                  "In der finalen App würden hier die SMS/E-Mail-Logs "
                  "und Notfallkontakte angezeigt.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),

                // Aktionen
                if (!isResolved)
                  ElevatedButton.icon(
                    onPressed: _updating ? null : _markResolved,
                    icon: _updating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    label: Text(
                      _updating
                          ? "Aktualisiere..."
                          : "Alarm als gelöst markieren (Demo)",
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}