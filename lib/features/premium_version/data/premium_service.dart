import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Ruft den Premiumstatus ab
  Future<Map<String, dynamic>> getPremiumStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {"active": false};

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};

    return data['premium'] ?? {"active": false};
  }

  /// Aktiviert Premium (Demo)
  Future<void> activatePremiumDemo() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
      'premium': {
        'active': true,
        'plan': "demo",
        'activatedAt': FieldValue.serverTimestamp(),
        'expiresAt': null, // späteres Abo-Modell
      }
    }, SetOptions(merge: true));
  }
}