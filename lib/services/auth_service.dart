import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> _createFirestoreUserDocument(User user, String email, String? displayName) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      debugPrint('Creating Firestore user document for ${user.uid}');
      await userDocRef.set({
        'full_name': displayName ?? 'New Student', // Will be updated if provided during registration
        'email': email,
        'contact': '',
        'role': 'student', 
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error during sign-in: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      debugPrint('General Error during sign-in: $e');
      throw Exception('An unexpected error occurred during sign-in.');
    }
  }

  // UPDATED: Accepts fullName parameter
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password, String fullName) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Pass the fullName explicitly
        await _createFirestoreUserDocument(userCredential.user!, email, fullName);
        
        await Future.delayed(const Duration(seconds: 2)); 
        await userCredential.user!.getIdTokenResult(true);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error during sign-up: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      debugPrint('General Error during sign-up: $e');
      throw Exception('An unexpected error occurred during sign-up.');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _createFirestoreUserDocument(
          userCredential.user!,
          userCredential.user!.email!,
          userCredential.user!.displayName, // Google display name
        );
        
        await Future.delayed(const Duration(seconds: 2)); 
        await userCredential.user!.getIdTokenResult(true);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error during Google sign-in: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      debugPrint('General Error during Google sign-in: $e');
      throw Exception('An unexpected error occurred during Google Sign-in.');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Error during sign-out: $e');
      throw Exception('Failed to sign out.');
    }
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<String?> getUserRole(User user) async {
    try {
      IdTokenResult idTokenResult = await user.getIdTokenResult(true);
      return idTokenResult.claims?['role'] as String?;
    } catch (e) {
      debugPrint('Error getting custom claims for user ${user.uid}: $e');
      return null;
    }
  }
}
