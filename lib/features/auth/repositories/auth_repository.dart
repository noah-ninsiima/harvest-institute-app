import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../shared/models/user_model.dart';
import '../controllers/auth_controller.dart'; // Import for userProvider

final authRepositoryProvider = Provider((ref) => AuthRepository(ref));

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Ref _ref;

  AuthRepository(this._ref);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Check if user exists in Firestore, if not create one
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // Default role is student for new Google sign-ins
          final newUser = UserModel(
            uid: user.uid,
            email: user.email!,
            fullName: user.displayName ?? 'No Name',
            role: UserRole.student,
            contact: '',
            createdAt: DateTime.now(),
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap());
        }
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    required String contact,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        final newUser = UserModel(
          uid: user.uid,
          email: email,
          fullName: fullName,
          role: role,
          contact: contact,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Future<void> updateUserData({
    required String uid,
    required String fullName,
    required String contact,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fullName': fullName,
        'contact': contact,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // 1. Sign out from Firebase
      await _auth.signOut();

      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore if Google Sign In fails (e.g. if not logged in with Google)
      }

      // 2. Clear Moodle tokens (and any other secure data)
      await _secureStorage.deleteAll();

      // 3. Crucial: Invalidate Riverpod state
      // This ensures the app detects the logout and redirects to LoginScreen
      // We invalidate the provider that holds the user state
      // Assuming 'userProvider' is the one in AuthController or similar
      // Note: In the AuthController file we saw userProvider defined as StreamProvider.
      // Invalidating it will force it to re-evaluate (which will see null user)
      // But the StreamProvider depends on authStateChangesProvider.
      // Since we signed out of Firebase, authStateChangesProvider will emit null.
      // So userProvider will also update.
      // But explicit invalidation is good practice as requested.

      // Since we don't have direct access to the provider definitions here (they are in another file),
      // we rely on the caller (AuthController) to invalidate, OR we use the container if passed.
      // But the User request said: "Update AuthRepository.logout() ... ref.invalidate(userProvider)"
      // The AuthRepository has a 'Ref' passed in constructor.

      // We need to make sure we are importing the userProvider correctly or using a name that resolves.
      // The userProvider is in AuthController file, which is imported.
      // However, we have a circular dependency potential if we import auth_controller.dart here.
      // But checking the imports: import '../controllers/auth_controller.dart'; is there.

      // Wait, in the file I read, 'userProvider' was in `auth_controller.dart`.
      // Let's check if `userProvider` is exported or available.

      // If userProvider is not available here, we might need to skip this line or fix imports.
      // Based on previous file read of `auth_controller.dart`, `userProvider` is defined there.
      // Let's assume the import works.

      // However, `userProvider` in `auth_controller.dart` was:
      // final userProvider = StreamProvider<UserModel?>((ref) { ... });

      // In the original code I read for AuthRepository, line 148 was:
      // _ref.invalidate(userProvider);
      // And line 7 was: import '../controllers/auth_controller.dart';
      // So it should be fine.

      _ref.invalidate(userProvider);
    } catch (e) {
      // Log error but ensure logout proceeds if possible
      print('Error during logout: $e');
      rethrow;
    }
  }
}
