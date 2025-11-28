import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelfieCaptureScreen extends StatefulWidget {
  final String inviteId;

  const SelfieCaptureScreen({
    Key? key,
    required this.inviteId,
  }) : super(key: key);

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  CameraController? _controller;
  bool _initializing = true;
  bool _hasError = false;
  XFile? _capturedFile;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      // Frontkamera verwenden, falls vorhanden
      CameraDescription camera = cameras.first;
      for (final c in cameras) {
        if (c.lensDirection == CameraLensDirection.front) {
          camera = c;
          break;
        }
      }

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      debugPrint("Fehler beim Initialisieren der Kamera: $e");
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final file = await _controller!.takePicture();
      setState(() {
        _capturedFile = file;
      });
    } catch (e) {
      debugPrint("Fehler beim Aufnehmen des Fotos: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Aufnehmen des Fotos: $e")),
      );
    }
  }

  Future<void> _uploadSelfie() async {
    if (_capturedFile == null) return;

    setState(() {
      _uploading = true;
    });

    try {
      // 👉 WICHTIG:
      // Hier laden wir aktuell NICHT zu Firebase Storage hoch,
      // sondern markieren nur in Firestore:
      // "Selfie vorhanden / hochgeladen".
      //
      // So ist die App stabil, auch wenn Storage noch nicht
      // vollständig konfiguriert ist.

      final inviteRef = FirebaseFirestore.instance
          .collection('invites')
          .doc(widget.inviteId);

      final snap = await inviteRef.get();
      final data = snap.data();
      final ownerUid = data != null ? data['ownerUid'] as String? : null;

      final updateData = {
        'selfiePresent': true,
        'selfieVerified': true, // aktuell: automatisch "ok"
        'selfieUpdatedAt': FieldValue.serverTimestamp(),
      };

      // globales Invite aktualisieren
      await inviteRef.set(updateData, SetOptions(merge: true));

      // Spiegelung bei der Frau
      if (ownerUid != null) {
        final userInviteRef = FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .collection('invites')
            .doc(widget.inviteId);

        await userInviteRef.set(updateData, SetOptions(merge: true));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Selfie wurde markiert. Die Frau sieht jetzt, dass eines vorliegt."),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Fehler beim Selfie-Speichern: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Speichern des Selfies: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Selfie aufnehmen"),
          backgroundColor: Colors.pink,
        ),
        body: const Center(
          child: Text(
            "Kamera konnte nicht initialisiert werden.\n"
            "Bitte erlaube den Kamerazugriff im Browser/System.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Selfie aufnehmen"),
        backgroundColor: Colors.pink,
      ),
      body: Column(
        children: [
          Expanded(
            child: _capturedFile == null
                ? CameraPreview(_controller!)
                : Container(
                    color: Colors.black12,
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _capturedFile == null
                ? ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    label: const Text("Foto aufnehmen"),
                  )
                : Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 40,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Foto aufgenommen. Du kannst es jetzt speichern.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _uploading ? null : _uploadSelfie,
                        icon: _uploading
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
                          backgroundColor: Colors.pink,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        label: Text(
                          _uploading ? "Speichere..." : "Selfie speichern",
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _uploading
                            ? null
                            : () {
                                setState(() {
                                  _capturedFile = null;
                                });
                              },
                        child: const Text("Neu aufnehmen"),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}