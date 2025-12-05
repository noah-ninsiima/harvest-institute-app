import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/moodle_auth_service.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../dashboard/screens/teacher_dashboard_screen.dart';
import '../../dashboard/screens/student_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../controllers/auth_controller.dart';

class RoleCheckWrapper extends ConsumerStatefulWidget {
  const RoleCheckWrapper({super.key});

  @override
  ConsumerState<RoleCheckWrapper> createState() => _RoleCheckWrapperState();
}

class _RoleCheckWrapperState extends ConsumerState<RoleCheckWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final moodleState = ref.watch(authControllerProvider);

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Check Firebase Auth (Primary/Legacy)
        final firebaseUser = snapshot.data;
        if (firebaseUser != null) {
          return RoleResolver(user: firebaseUser, authService: _authService);
        }

        // 2. Check Moodle Auth (Secondary/New)
        final moodleUser = moodleState.value;
        if (moodleUser != null) {
          return MoodleRoleResolver(moodleUser: moodleUser);
        }

        // 3. Loading State
        if (snapshot.connectionState == ConnectionState.waiting || moodleState.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 4. Not Authenticated
        return const LoginScreen();
      },
    );
  }
}

/// Resolves role for Firebase Authenticated users (via Claims or Firestore)
class RoleResolver extends StatefulWidget {
  final User user;
  final AuthService authService;

  const RoleResolver({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<RoleResolver> createState() => _RoleResolverState();
}

class _RoleResolverState extends State<RoleResolver> {
  Future<String?>? _roleFuture;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  void _fetchRole() {
    setState(() {
      _roleFuture = _getRoleWithRetry();
    });
  }

  Future<String?> _getRoleWithRetry() async {
    String? role = await widget.authService.getUserRole(widget.user);
    
    // If role is null, check if we should retry
    if (role == null && _retryCount < _maxRetries) {
      _retryCount++;
      debugPrint('Role not found (Firebase), retrying ($_retryCount/$_maxRetries)...');
      await Future.delayed(const Duration(seconds: 2));
      return _getRoleWithRetry();
    }
    
    return role;
  }

  @override
  Widget build(BuildContext context) {
    return _buildDashboardLoader(_roleFuture, () async {
      await widget.authService.signOut();
    });
  }

  Widget _buildDashboardLoader(Future<String?>? future, VoidCallback onSignOut) {
    return FutureBuilder<String?>(
      future: future,
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting up your profile...'),
                ],
              ),
            ),
          );
        }

        final String? role = roleSnapshot.data;
        return _navigateBasedOnRole(role, onSignOut);
      },
    );
  }

  Widget _navigateBasedOnRole(String? role, VoidCallback onSignOut) {
    if (role == 'admin') {
      return const AdminDashboardScreen();
    } else if (role == 'instructor' || role == 'teacher') {
      return const TeacherDashboard();
    } else if (role == 'student') {
      return const StudentDashboardScreen();
    } else {
      return _buildErrorScreen(onSignOut);
    }
  }

  Widget _buildErrorScreen(VoidCallback onSignOut) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'User role not assigned.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This usually happens for new accounts while we set things up. Please try refreshing.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _retryCount = 0;
                  _fetchRole();
                },
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: onSignOut,
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resolves role for Moodle Authenticated users (via Firestore Document)
class MoodleRoleResolver extends ConsumerStatefulWidget {
  final MoodleUserModel moodleUser;

  const MoodleRoleResolver({
    super.key,
    required this.moodleUser,
  });

  @override
  ConsumerState<MoodleRoleResolver> createState() => _MoodleRoleResolverState();
}

class _MoodleRoleResolverState extends ConsumerState<MoodleRoleResolver> {
  Future<String?>? _roleFuture;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  void _fetchRole() {
    setState(() {
      _roleFuture = _getRoleFromFirestoreWithRetry();
    });
  }

  Future<String?> _getRoleFromFirestoreWithRetry() async {
    try {
      final moodleUid = 'moodle_${widget.moodleUser.userid}';
      final doc = await FirebaseFirestore.instance.collection('users').doc(moodleUid).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('role')) {
          return data['role'] as String;
        }
      }
    } catch (e) {
      debugPrint('Error fetching Moodle user role: $e');
    }

    if (_retryCount < _maxRetries) {
      _retryCount++;
      debugPrint('Role not found (Moodle), retrying ($_retryCount/$_maxRetries)...');
      await Future.delayed(const Duration(seconds: 2));
      return _getRoleFromFirestoreWithRetry();
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Syncing Moodle Profile...'),
                ],
              ),
            ),
          );
        }

        final String? role = roleSnapshot.data;

        if (role == 'admin') {
          return const AdminDashboardScreen();
        } else if (role == 'instructor' || role == 'teacher') {
          return const TeacherDashboard();
        } else if (role == 'student') {
          return const StudentDashboardScreen();
        } else {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Setup Incomplete',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We could not find your role information. This might be a sync issue.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        _retryCount = 0;
                        _fetchRole();
                      },
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).signOut(ref, context);
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
