import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../../shared/models/user_model.dart';
import '../widgets/role_check_wrapper.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
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

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signInWithEmailAndPassword(email, password));
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signInWithGoogle());
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    required String contact,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.registerUser(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      contact: contact,
    ));
  }

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
      await _authRepository.signOut();
      ref.invalidate(userProvider);
      ref.invalidate(authStateChangesProvider);
      state = const AsyncValue.data(null);
      
      // Explicitly navigate to RoleCheckWrapper (Root) to force a fresh state check
      // This handles cases where the UI might not update automatically, especially on Web
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
