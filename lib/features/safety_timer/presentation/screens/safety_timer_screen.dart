import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SafetyTimerScreen extends StatefulWidget {
  const SafetyTimerScreen({Key? key}) : super(key: key);

  @override
  State<SafetyTimerScreen> createState() => _SafetyTimerScreenState();
}

class _SafetyTimerScreenState extends State<SafetyTimerScreen> {
  int _selectedMinutes = 60; // Standard: 60 Minuten
  bool _isRunning = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  String? _sessionId;

  int get _totalSeconds => _selectedMinutes * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startTimer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kein angemeldeter Benutzer gefunden.")),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _remainingSeconds = _totalSeconds;
    });

    // Firestore-Dokument für die Sitzung anlegen
    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('safetySessions')
        .add({
      'startedAt': FieldValue.serverTimestamp(),
      'durationMinutes': _selectedMinutes,
      'status': 'running', // running / ended_ok / timeout
      'lastCheckInAt': FieldValue.serverTimestamp(),
    });

    _sessionId = docRef.id;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _onTimerTimeout();
      }
    });
  }

  Future<void> _onTimerTimeout() async {
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });

    await _updateSessionStatus('timeout');

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Timer abgelaufen"),
        content: const Text(
          "Dein Sicherheitstimer ist abgelaufen.\n"
          "In der finalen Version würden jetzt deine Notfallkontakte benachrichtigt werden.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSessionStatus(String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _sessionId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('safetySessions')
        .doc(_sessionId)
        .set({
      'status': status,
      'lastCheckInAt': FieldValue.serverTimestamp(),
      if (status != 'running') 'endedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _extendTimer() async {
    if (!_isRunning) return;

    setState(() {
      _remainingSeconds += _totalSeconds; // gleiche Zeit nochmal
    });

    await _updateSessionStatus('running');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Timer verlängert. Wir fragen später erneut nach."),
      ),
    );
  }

  Future<void> _endMeetingSafely() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });

    await _updateSessionStatus('ended_ok');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Treffen als sicher beendet markiert.")),
    );

    Navigator.pop(context); // zurück zum HomeScreen
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return "$mm:$ss";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sicherheitstimer"),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isRunning ? _buildRunningView() : _buildSetupView(),
      ),
    );
  }

  Widget _buildSetupView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Timer für dein Treffen einstellen",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          "Während des Treffens läuft ein Timer. "
          "Wenn du dich nicht rechtzeitig meldest, werden deine Notfallkontakte informiert "
          "(in dieser Version nur als Vorbereitung).",
        ),
        const SizedBox(height: 24),
        const Text(
          "Dauer auswählen:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _DurationChip(
              minutes: 30,
              selectedMinutes: _selectedMinutes,
              onSelected: () => setState(() => _selectedMinutes = 30),
            ),
            _DurationChip(
              minutes: 60,
              selectedMinutes: _selectedMinutes,
              onSelected: () => setState(() => _selectedMinutes = 60),
            ),
            _DurationChip(
              minutes: 90,
              selectedMinutes: _selectedMinutes,
              onSelected: () => setState(() => _selectedMinutes = 90),
            ),
            _DurationChip(
              minutes: 120,
              selectedMinutes: _selectedMinutes,
              onSelected: () => setState(() => _selectedMinutes = 120),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          "Aktuelle Auswahl: $_selectedMinutes Minuten",
          style: const TextStyle(fontSize: 16),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _startTimer,
          icon: const Icon(Icons.play_arrow),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            minimumSize: const Size(double.infinity, 50),
          ),
          label: const Text("Timer starten"),
        ),
      ],
    );
  }

  Widget _buildRunningView() {
    final progress =
        _totalSeconds == 0 ? 0.0 : _remainingSeconds / _totalSeconds.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Timer läuft",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          "Wir erinnern dich rechtzeitig daran, zu bestätigen, "
          "dass alles in Ordnung ist.",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            _formatTime(_remainingSeconds),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 8,
        ),
        const SizedBox(height: 32),
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
          onPressed: _endMeetingSafely,
          icon: const Icon(Icons.lock_open),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          label: const Text("Treffen sicher beendet"),
        ),
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  final int minutes;
  final int selectedMinutes;
  final VoidCallback onSelected;

  const _DurationChip({
    Key? key,
    required this.minutes,
    required this.selectedMinutes,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selected = minutes == selectedMinutes;

    return ChoiceChip(
      label: Text("$minutes Min"),
      selected: selected,
      selectedColor: Colors.pink.shade100,
      onSelected: (_) => onSelected(),
    );
  }
}