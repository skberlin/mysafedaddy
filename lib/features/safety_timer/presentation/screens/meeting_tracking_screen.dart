import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MeetingTrackingScreen extends StatefulWidget {
  final String inviteId;

  const MeetingTrackingScreen({
    Key? key,
    required this.inviteId,
  }) : super(key: key);

  @override
  State<MeetingTrackingScreen> createState() => _MeetingTrackingScreenState();
}

class _MeetingTrackingScreenState extends State<MeetingTrackingScreen> {
  String? _uid;
  bool _loading = true;
  bool _permissionDenied = false;

  Position? _currentPosition;
  String _meetingStatus = 'none'; // none | active | ended

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _init();
  }

  Future<void> _init() async {
    if (_uid == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/splash', (_) => false);
      }
      return;
    }

    try {
      await _loadMeetingStatus();
      await _ensureLocationPermission();
      if (!_permissionDenied) {
        await _startMeetingIfNeeded();
        await _updateLocation();
        await _autoStartTimerIfNeeded(); // ⬅️ Auto-Timer-Start
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMeetingStatus() async {
    final inviteRef =
        FirebaseFirestore.instance.collection('invites').doc(widget.inviteId);
    final snap = await inviteRef.get();
    if (snap.exists) {
      final data = snap.data()!;
      _meetingStatus = (data['meetingStatus'] ?? 'none') as String;
    }
  }

  Future<void> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Standortdienste sind deaktiviert. Bitte aktivieren."),
          ),
        );
      }
      _permissionDenied = true;
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _permissionDenied = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Keine Standortberechtigung. "
              "Bitte in den Systemeinstellungen freigeben.",
            ),
          ),
        );
      }
    } else {
      _permissionDenied = false;
    }
  }

  Future<void> _startMeetingIfNeeded() async {
    if (_meetingStatus == 'active') return;

    final update = {
      'meetingStatus': 'active',
      'meetingStartedAt': FieldValue.serverTimestamp(),
    };

    final inviteRef =
        FirebaseFirestore.instance.collection('invites').doc(widget.inviteId);
    await inviteRef.set(update, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('invites')
        .doc(widget.inviteId)
        .set(update, SetOptions(merge: true));

    _meetingStatus = 'active';
  }

  Future<void> _updateLocation() async {
    if (_permissionDenied) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = pos;
      });

      final update = {
        'womanLastLat': pos.latitude,
        'womanLastLng': pos.longitude,
        'womanLastUpdatedAt': FieldValue.serverTimestamp(),
      };

      final inviteRef =
          FirebaseFirestore.instance.collection('invites').doc(widget.inviteId);
      await inviteRef.set(update, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('invites')
          .doc(widget.inviteId)
          .set(update, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Standort-Update: $e")),
      );
    }
  }

  /// Startet automatisch einen Sicherheitstimer (30 Min),
  /// wenn für dieses Treffen noch kein aktiver Timer existiert.
  Future<void> _autoStartTimerIfNeeded() async {
    if (_uid == null) return;

    const defaultMinutes = 30;

    final inviteRef =
        FirebaseFirestore.instance.collection('invites').doc(widget.inviteId);
    final inviteSnap = await inviteRef.get();

    if (!inviteSnap.exists) return;

    final inviteData = inviteSnap.data()!;
    final existingTimerId = inviteData['activeTimerId'] as String?;

    // Wenn bereits ein Timer verknüpft ist, nichts tun
    if (existingTimerId != null && existingTimerId.isNotEmpty) return;

    final userTimersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('safety_timers');

    final timerDoc = userTimersRef.doc();
    final timerId = timerDoc.id;
    final totalSeconds = defaultMinutes * 60;

    final timerData = {
      'userUid': _uid,
      'inviteId': widget.inviteId,
      'status': 'running', // running | completed | expired | cancelled
      'durationMinutes': defaultMinutes,
      'remainingSeconds': totalSeconds,
      'startedAt': FieldValue.serverTimestamp(),
      'extensions': 0,
      'autoStarted': true,
    };

    // Beim Nutzer speichern
    await timerDoc.set(timerData);

    // Beim Invite referenzieren + in Unterkollektion speichern
    await inviteRef.set({
      'activeTimerId': timerId,
      'lastTimerStartedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await inviteRef.collection('timers').doc(timerId).set(timerData);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Sicherheitstimer wurde automatisch auf 30 Minuten gestartet.",
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _endMeeting() async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Treffen sicher beendet?"),
            content: const Text(
              "Wenn du das Treffen als sicher beendet markierst, "
              "wird das GPS-Tracking für dieses Treffen gestoppt.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Abbrechen"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Ja, Treffen beendet"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final update = {
      'meetingStatus': 'ended',
      'meetingEndedAt': FieldValue.serverTimestamp(),
    };

    final inviteRef =
        FirebaseFirestore.instance.collection('invites').doc(widget.inviteId);
    await inviteRef.set(update, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('invites')
        .doc(widget.inviteId)
        .set(update, SetOptions(merge: true));

    if (!mounted) return;

    setState(() {
      _meetingStatus = 'ended';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Treffen als sicher beendet markiert.")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_permissionDenied) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Treffen"),
          backgroundColor: Colors.pink,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "Standortberechtigung wurde verweigert.\n\n"
              "Aktiviere die Berechtigung, um das Treffen mit GPS abzusichern.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    String statusText;
    Color statusColor;
    if (_meetingStatus == 'ended') {
      statusText = "Treffen sicher beendet";
      statusColor = Colors.green;
    } else {
      statusText = "Treffen aktiv";
      statusColor = Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Treffen absichern"),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Während des Treffens wird deine Position in regelmäßigen "
              "Abständen gespeichert. Im Alarmfall können so Notfallkontakte "
              "informiert werden.\n\n"
              "Für dieses Treffen wurde automatisch ein Sicherheitstimer gestartet.",
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Aktuelle Position (Demo)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_currentPosition == null)
                    const Text(
                      "Noch keine Position geladen.",
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Text(
                      "Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}\n"
                      "Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}",
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _updateLocation,
                    icon: const Icon(Icons.my_location),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                    ),
                    label: const Text("Standort jetzt aktualisieren"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _meetingStatus == 'ended' ? null : _endMeeting,
              icon: const Icon(Icons.lock),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              label: const Text("Treffen sicher beendet"),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/safety-timer',
                  arguments: {'inviteId': widget.inviteId},
                );
              },
              icon: const Icon(Icons.timer),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              label: const Text("Sicherheitstimer öffnen"),
            ),
          ],
        ),
      ),
    );
  }
}