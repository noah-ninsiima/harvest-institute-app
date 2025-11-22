import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Initialize Firestore

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // --- Helper to create Firestore user document with default 'student' role ---
  // This is called after any successful sign-up (Email/Pass or Google)
  // The custom claim ('role: student') will be set by a Cloud Function (addDefaultUserRole)
  Future<void> _createFirestoreUserDocument(User user, String email, String? displayName) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    // Only create if the document doesn't already exist
    final userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      debugPrint('Creating Firestore user document for ${user.uid} with default role: student');
      await userDocRef.set({
        'full_name': displayName ?? 'New Student',
        'email': email,
        'contact': '', // Can be updated later by the student
        'role': 'student', // Default role in Firestore doc (Claims are set by CF)
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      debugPrint('Firestore user document for ${user.uid} already exists.');
    }
  }


  // --- Sign In with Email & Password ---
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('User signed in: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error during sign-in: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      debugPrint('General Error during sign-in: $e');
      throw Exception('An unexpected error occurred during sign-in.');
    }
  }

  // --- Create User (Sign Up) with Email & Password ---
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('User signed up: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        // Create corresponding Firestore user document immediately
        await _createFirestoreUserDocument(userCredential.user!, email, null);
        
        // Wait briefly to allow Cloud Function to process the claim assignment
        // This is a client-side optimistic delay; robust apps might poll or handle 'pending' state
        // However, since we control the UX, we can also optimistically treat them as student if claim is missing initially
        await Future.delayed(const Duration(seconds: 2)); 
        
        // Force token refresh immediately to try and pick up the new claim
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

  // --- Sign In with Google ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Begin interactive Google Sign-In process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the Google credential
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      debugPrint('User signed in with Google: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        // Create corresponding Firestore user document immediately
        await _createFirestoreUserDocument(
          userCredential.user!,
          userCredential.user!.email!, // Google guarantees email
          userCredential.user!.displayName, // Use display name from Google
        );
        
        // Wait briefly to allow Cloud Function to process the claim assignment
        await Future.delayed(const Duration(seconds: 2)); 
        
        // Force token refresh
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

  // --- Sign Out ---
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await GoogleSignIn().signOut(); // Also sign out from Google if signed in via Google
      debugPrint('User signed out.');
    } catch (e) {
      debugPrint('Error during sign-out: $e');
      throw Exception('Failed to sign out.');
    }
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // --- Get User Role (from Custom Claims) ---
  Future<String?> getUserRole(User user) async {
    try {
      // Force refresh of ID token to ensure latest claims are fetched.
      IdTokenResult idTokenResult = await user.getIdTokenResult(true);
      
      // Fallback: If role claim is missing but user was just created, 
      // we can default to 'student' if we trust the client flow, 
      // BUT strictly relying on claims is safer. 
      // If the cloud function hasn't finished yet, this might be null.
      // We can implement a retry or return a 'pending' state if needed.
      
      return idTokenResult.claims?['role'] as String?;
    } catch (e) {
      debugPrint('Error getting custom claims for user ${user.uid}: $e');
      return null;
    }
  }
}
