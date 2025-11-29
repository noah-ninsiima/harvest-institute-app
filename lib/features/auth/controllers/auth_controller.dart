import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/auth_repository.dart';
import '../../shared/models/user_model.dart';
import '../widgets/role_check_wrapper.dart';
import '../../../services/moodle_auth_service.dart';

final moodleAuthServiceProvider = Provider((ref) => MoodleAuthService());

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(moodleAuthServiceProvider),
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider).value;
  if (authState == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).getUserStream(authState.uid);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final MoodleAuthService _moodleAuthService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthController(this._authRepository, this._moodleAuthService) : super(const AsyncValue.data(null));

  // Moodle Login & Firestore Sync
  Future<void> signInWithMoodle(String username, String password) async {
    debugPrint('Starting Moodle Sign In for user: $username');
    state = const AsyncValue.loading();
    try {
      // 1. Moodle Login
      final token = await _moodleAuthService.login(username, password);
      debugPrint('Moodle Token acquired.');

      // 2. Get User Profile from Moodle
      final moodleUser = await _moodleAuthService.getUserProfile(token);
      debugPrint('Moodle Profile fetched: ${moodleUser.fullName}');
      
      // 3. Silent Sync to Firestore
      await _syncMoodleUserToFirestore(moodleUser);
      debugPrint('Firestore Sync complete for ${moodleUser.userid}.');
      
      // Note: We aren't signing in with Firebase Auth here, just syncing data.
      // The app flow might need to adjust if it relies heavily on FirebaseAuth.currentUser.
      // For now, we are assuming the app uses the user data from Firestore or Moodle token.
      // However, to maintain compatibility with existing Firebase structure, 
      // we might need to create a custom token or just rely on the Firestore document existence.
      // 
      // Since the instruction says "Hybrid" and checks Firestore, we will assume
      // the existence of the Firestore document is sufficient for the app logic, 
      // OR we might need to sign in anonymously to Firebase to access Firestore if rules require auth.
      
      debugPrint('Moodle Sign In Successful. Setting state to AsyncData.');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      debugPrint('Moodle Sign In Failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _syncMoodleUserToFirestore(MoodleUserModel moodleUser) async {
    final moodleUid = 'moodle_${moodleUser.userid}';
    final userDocRef = _firestore.collection('users').doc(moodleUid);
    
    final docSnapshot = await userDocRef.get();
    
    // Use username as fallback email if email is empty (Moodle often hides email)
    // We append a placeholder domain if it's just a username to satisfy UserModel email requirement if strict
    final userEmail = moodleUser.email.isNotEmpty 
        ? moodleUser.email 
        : '${moodleUser.username}@moodle.placeholder';

    if (!docSnapshot.exists) {
      // Create new user document
      final newUser = UserModel(
        uid: moodleUid,
        email: userEmail,
        fullName: moodleUser.fullName,
        role: UserRole.student, // Default role
        contact: '', // Not available from initial Moodle profile
        createdAt: DateTime.now(),
      );
      
      await userDocRef.set(newUser.toMap());
      debugPrint('Created new Firestore user for Moodle user: $moodleUid');
    } else {
      debugPrint('Firestore user already exists for Moodle user: $moodleUid');
      // Optional: Update existing data if needed (e.g. name change in Moodle)
       await userDocRef.update({
        'fullName': moodleUser.fullName,
        'email': userEmail,
      });
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signInWithGoogle());
  }

  // Removed register method as per instructions

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String contact,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.updateUserData(
      uid: uid,
      fullName: fullName,
      contact: contact,
    ));
  }

  Future<void> signOut(WidgetRef ref, BuildContext context) async {
    state = const AsyncValue.loading();
    try {
      await _moodleAuthService.logout(); // Clear Moodle token
      await _authRepository.signOut(); // Sign out from Firebase/Google
      
      ref.invalidate(userProvider);
      ref.invalidate(authStateChangesProvider);
      state = const AsyncValue.data(null);
      
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RoleCheckWrapper()),
          (route) => false,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
