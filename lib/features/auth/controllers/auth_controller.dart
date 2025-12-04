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

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<MoodleUserModel?>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(moodleAuthServiceProvider),
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userProvider = StreamProvider<UserModel?>((ref) {
  // 1. Try Firebase Auth (Preferred)
  final authState = ref.watch(authStateChangesProvider).value;
  if (authState != null) {
    return ref.watch(authRepositoryProvider).getUserStream(authState.uid);
  }

  // 2. Try Moodle Auth (Fallback for Moodle-only login)
  final moodleState = ref.watch(authControllerProvider).value;
  if (moodleState != null) {
    // Construct the expected Firestore ID for Moodle users
    final moodleUid = 'moodle_${moodleState.userid}';
    return ref.watch(authRepositoryProvider).getUserStream(moodleUid);
  }

  // 3. Not authenticated
  return Stream.value(null);
});

// Deprecated: Use authControllerProvider instead for Moodle profile
final currentUserProfileProvider =
    FutureProvider<MoodleUserModel?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  return authState.value;
});

class AuthController extends StateNotifier<AsyncValue<MoodleUserModel?>> {
  final AuthRepository _authRepository;
  final MoodleAuthService _moodleAuthService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthController(this._authRepository, this._moodleAuthService)
      : super(const AsyncValue.data(null)) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = const AsyncValue.loading();
    try {
      final token = await _moodleAuthService.getStoredToken();
      if (token != null) {
        final user = await _moodleAuthService.getUserProfile(token);
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      debugPrint('Auth check failed: $e');
      state = const AsyncValue.data(null);
    }
  }

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

      // CRITICAL: Update state immediately so UI can react
      state = AsyncValue.data(moodleUser);

      // 3. Silent Sync to Firestore
      await _syncMoodleUserToFirestore(moodleUser);
      debugPrint('Firestore Sync complete for ${moodleUser.userid}.');

      debugPrint('Moodle Sign In Successful.');
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
        username: moodleUser.username,
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
    // Google sign in logic doesn't return Moodle user, so we might need to handle state differently
    // or assume Google sign in is separate.
    // For now, leaving as is, but catching errors.
    try {
      await _authRepository.signInWithGoogle();
      // Google Sign In doesn't provide Moodle profile, so state remains null or previous
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String contact,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.updateUserData(
        uid: uid,
        fullName: fullName,
        contact: contact,
      );
      // If we had the user object in state, we should update it here,
      // but since this updates Firestore and not Moodle, we might not update the local Moodle state.
      // Ideally we'd refetch or update local copy.

      // Restore previous state if possible or keep as is (re-fetch handled by checkAuthStatus if needed)
      if (state.value != null) {
        // Optimistic update? Or just restore.
        state = AsyncValue.data(state.value);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut(WidgetRef ref, BuildContext context) async {
    state = const AsyncValue.loading();
    try {
      // Best effort logout sequence
      try {
        await _moodleAuthService.logout(); // Clear Moodle token
      } catch (e) {
        debugPrint('Error clearing Moodle token: $e');
      }

      try {
        await _authRepository.signOut(); // Sign out from Firebase/Google
      } catch (e) {
        debugPrint('Error signing out from Firebase: $e');
      }

      // Invalidate Riverpod state
      ref.invalidate(userProvider);
      ref.invalidate(authStateChangesProvider);
      // ref.invalidate(currentUserProfileProvider); // No longer needed as it depends on this controller

      state = const AsyncValue.data(null);
    } catch (e, st) {
      debugPrint('SignOut Error: $e');
      state = AsyncValue.error(e, st);
    } finally {
      // Always navigate back to the login screen/RoleCheckWrapper
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RoleCheckWrapper()),
          (route) => false,
        );
      }
    }
  }
}
