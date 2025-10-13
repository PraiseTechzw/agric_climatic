import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> savePhoneNumber(String e164Phone) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('user_profiles').doc(uid).set({
      'phone_e164': e164Phone,
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('user_profiles').doc(uid).get();
    return doc.data();
  }
}



