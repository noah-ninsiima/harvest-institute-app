import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

final profileProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  return ProfileController();
});

class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController() : super(const AsyncValue.data(null));

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> uploadImage(String uid) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      state = const AsyncValue.loading();
      // Use provided uid instead of _auth.currentUser
      // final user = _auth.currentUser;
      // if (user == null) throw Exception('No user logged in');

      final ref = _storage.ref().child('user_images/$uid.jpg');
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      await _firestore.collection('users').doc(uid).update({
        'photoUrl': url,
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    required String uid,
    required String username,
    required String contact,
    required String fullName,
    required String email,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Use provided uid
      // final user = _auth.currentUser;
      // if (user == null) throw Exception('No user logged in');

      await _firestore.collection('users').doc(uid).update({
        'username': username,
        'contact': contact,
        'fullName': fullName,
        'email': email,
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');
      if (user.email == null) throw Exception('User email not found');

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
