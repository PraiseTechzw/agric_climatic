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

  /// Check if user has a valid phone number in their profile
  static Future<bool> hasValidPhoneNumber() async {
    try {
      final profile = await getCurrentUserProfile();
      final phone = profile?['phone_e164'] as String?;
      return phone != null && phone.isNotEmpty && phone.startsWith('+263');
    } catch (e) {
      return false;
    }
  }

  /// Update user profile with additional fields
  static Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('user_profiles').doc(uid).set({
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
