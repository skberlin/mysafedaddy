import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SafetyTimerScreen extends StatefulWidget {
  /// Wenn der Timer aus einem Treffen heraus geöffnet wird,
  /// ist hier die inviteId des Treffens gesetzt.
  final String? inviteId;

  const SafetyTimerScreen({
    Key? key,
    this.inviteId,
  }) : super(key: key);

  @override
  State<SafetyTimerScreen> createState() => _SafetyTimerScreenState();
}

class _SafetyTimerScreenState extends State<SafetyTimerScreen> {
  String? _uid;

  int _selectedMinutes = 30;
  int _remainingSeconds = 0;
  Timer? _ticker;
  bool _running = false;
  bool _saving = false;
  String? _activeTimerId;

  bool _alarmCreated = false; // Damit Alarm nur einmal geschrieben wird

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

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _timersRef() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('safety_timers');
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _startTimer() async {
    if (_uid == null) return;

    setState(() {
      _saving = true;
      _alarmCreated = false; // bei neuem Timer Alarm-Flag zurücksetzen
    });

    try {
      // Wenn 0 Minuten ausgewählt sind → Testmodus mit 10 Sekunden
      _remainingSeconds =
          _selectedMinutes == 0 ? 10 : _selectedMinutes * 60;

      // neues Timer-Dokument in Firestore
      final doc = _timersRef().doc();
      _activeTimerId = doc.id;

      final data = {
        'userUid': _uid,
        'inviteId': widget.inviteId,
        'status': 'running', // running | completed | expired | cancelled
        'durationMinutes': _selectedMinutes,
        'remainingSeconds': _remainingSeconds,
        'startedAt': FieldValue.serverTimestamp(),
        'extensions': 0,
        'autoStarted': false,
      };

      await doc.set(data);

      // wenn mit Treffen verknüpft: Referenz unter invite speichern
      if (widget.inviteId != null) {
        final inviteRef = FirebaseFirestore.instance
            .collection('invites')
            .doc(widget.inviteId);

        await inviteRef.set(
          {
            'activeTimerId': _activeTimerId,
            'lastTimerStartedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await inviteRef.collection('timers').doc(_activeTimerId).set(data);
      }

      // lokaler Timer
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _ticker?.cancel();
            _running = false;
          }
        });

        if (_remainingSeconds <= 0) {
          _onTimerExpired();
        }
      });

      setState(() {
        _running = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Starten des Timers: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _extendTimer() async {
    if (!_running || _activeTimerId == null) return;

    setState(() {
      _remainingSeconds += _selectedMinutes * 60;
    });

    try {
      await _timersRef().doc(_activeTimerId).update({
        'remainingSeconds': _remainingSeconds,
        'extensions': FieldValue.increment(1),
      });

      if (widget.inviteId != null) {
        final inviteRef = FirebaseFirestore.instance
            .collection('invites')
            .doc(widget.inviteId);
        await inviteRef
            .collection('timers')
            .doc(_activeTimerId)
            .update({'remainingSeconds': _remainingSeconds});
      }
    } catch (e) {
      debugPrint("Fehler beim Verlängern des Timers: $e");
    }
  }

  Future<void> _markCompleted({bool safe = true}) async {
    _ticker?.cancel();
    setState(() {
      _running = false;
    });

    if (_activeTimerId == null) return;

    final update = {
      'status': safe ? 'completed' : 'cancelled',
      'completedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _timersRef()
          .doc(_activeTimerId)
          .set(update, SetOptions(merge: true));

      if (widget.inviteId != null) {
        final inviteRef = FirebaseFirestore.instance
            .collection('invites')
            .doc(widget.inviteId);

        await inviteRef
            .collection('timers')
            .doc(_activeTimerId)
            .set(update, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Fehler beim Abschließen des Timers: $e");
    }
  }

  /// Alarm-Datensatz in Firestore schreiben
  Future<void> _createAlarmRecord() async {
    if (_uid == null || _alarmCreated) return;

    _alarmCreated = true;

    final alarmsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('alarms');

    final alarmDoc = alarmsRef.doc();
    final alarmId = alarmDoc.id;

    double? lat;
    double? lng;
    String? meetingStatus;

    // Wenn Timer mit einem Treffen verknüpft ist, versuchen wir,
    // letzte Position und Meeting-Status aus der Einladung zu lesen.
    if (widget.inviteId != null) {
      final inviteSnap = await FirebaseFirestore.instance
          .collection('invites')
          .doc(widget.inviteId)
          .get();

      if (inviteSnap.exists) {
        final data = inviteSnap.data()!;
        lat = (data['womanLastLat'] as num?)?.toDouble();
        lng = (data['womanLastLng'] as num?)?.toDouble();
        meetingStatus = data['meetingStatus'] as String?;
      }
    }

    final alarmData = {
      'userUid': _uid,
      'inviteId': widget.inviteId,
      'timerId': _activeTimerId,
      'status': 'open', // open | notified | resolved
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'timer_expired',
      'locationLat': lat,
      'locationLng': lng,
      'meetingStatusAtAlarm': meetingStatus,
      'demoNotification': true, // Kennzeichnung: Demo-Alarm
    };

    try {
      await alarmDoc.set(alarmData);

      // Falls mit Einladung verknüpft, auch dort ablegen
      if (widget.inviteId != null) {
        final inviteRef = FirebaseFirestore.instance
            .collection('invites')
            .doc(widget.inviteId);

        await inviteRef
            .collection('alarms')
            .doc(alarmId)
            .set(alarmData);

        await inviteRef.set(
          {
            'lastAlarmId': alarmId,
            'lastAlarmAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint("Fehler beim Schreiben des Alarm-Datensatzes: $e");
    }
  }

  Future<void> _onTimerExpired() async {
    if (_activeTimerId == null) return;

    final update = {
      'status': 'expired',
      'expiredAt': FieldValue.serverTimestamp(),
    };

    try {
      // Timer-Status in Firestore aktualisieren
      await _timersRef()
          .doc(_activeTimerId)
          .set(update, SetOptions(merge: true));

      if (widget.inviteId != null) {
        final inviteRef = FirebaseFirestore.instance
            .collection('invites')
            .doc(widget.inviteId);

        await inviteRef
            .collection('timers')
            .doc(_activeTimerId)
            .set(update, SetOptions(merge: true));
      }

      // Alarm-Datensatz anlegen (User + optional Invite)
      await _createAlarmRecord();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Timer abgelaufen"),
          content: const Text(
            "Der Sicherheitstimer ist abgelaufen.\n\n"
            "In dieser Demo-Version wurden deine Alarmdaten in Firestore "
            "gespeichert. In der finalen Version würden jetzt deine "
            "Notfallkontakte automatisch per SMS/E-Mail informiert und der "
            "letzte Standort übermittelt.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Fehler beim Markieren als abgelaufen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_running) {
      // Auswahl-Ansicht
      return Scaffold(
        appBar: AppBar(
          title: const Text("Sicherheitstimer"),
          backgroundColor: Colors.pink,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Timer für dein Treffen einstellen",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Während des Treffens läuft ein Timer. "
                "Wenn du dich nicht rechtzeitig meldest, "
                "werden deine Notfallkontakte informiert "
                "(in dieser Version noch als Vorbereitung).",
              ),
              const SizedBox(height: 24),
              if (widget.inviteId != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Dieser Timer ist mit dem Treffen-Code verknüpft:\n${widget.inviteId}",
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              const Text(
                "Dauer auswählen:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  // Test-Option: 10 Sekunden
                  ChoiceChip(
                    label: const Text("10 Sek (Test)"),
                    selected: _selectedMinutes == 0,
                    onSelected: (_) {
                      setState(() {
                        _selectedMinutes = 0; // 0 Minuten = Testmodus
                      });
                    },
                    selectedColor: Colors.red,
                    labelStyle: TextStyle(
                      color: _selectedMinutes == 0
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  // Normale Optionen
                  ...[30, 60, 90, 120].map((m) {
                    final isSelected = _selectedMinutes == m;
                    return ChoiceChip(
                      label: Text("$m Min"),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedMinutes = m;
                        });
                      },
                      selectedColor: Colors.pink,
                      labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.white : Colors.black87,
                      ),
                    );
                  }).toList(),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _selectedMinutes == 0
                    ? "Aktuelle Auswahl: 10 Sekunden (Test)"
                    : "Aktuelle Auswahl: $_selectedMinutes Minuten",
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _saving ? null : _startTimer,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  minimumSize: const Size(double.infinity, 50),
                ),
                label: Text(_saving ? "Starte..." : "Timer starten"),
              ),
            ],
          ),
        ),
      );
    }

    // Laufende Timer-Ansicht
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sicherheitstimer"),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Timer läuft",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Wir erinnern dich rechtzeitig daran, zu bestätigen, "
              "dass alles in Ordnung ist.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              _formatDuration(_remainingSeconds),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _remainingSeconds /
                  (_selectedMinutes == 0
                      ? 10
                      : _selectedMinutes * 60),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _extendTimer,
              icon: const Icon(Icons.check),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              label: const Text("Alles ok, Timer verlängern"),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await _markCompleted(safe: true);
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.lock),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              label: const Text("Treffen sicher beendet"),
            ),
          ],
        ),
      ),
    );
  }
}