import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../dashboard/screens/instructor_dashboard_screen.dart';
import '../../dashboard/screens/student_dashboard_screen.dart';
import '../screens/login_screen.dart';

class RoleCheckWrapper extends StatefulWidget {
  const RoleCheckWrapper({super.key});

  @override
  State<RoleCheckWrapper> createState() => _RoleCheckWrapperState();
}

class _RoleCheckWrapperState extends State<RoleCheckWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final User? user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        } else {
          // User is authenticated, now check for role with retry logic
          return RoleResolver(user: user, authService: _authService);
        }
      },
    );
  }
}

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
      debugPrint('Role not found, retrying ($_retryCount/$_maxRetries)...');
      await Future.delayed(const Duration(seconds: 2));
      // Recursively call to retry
      return _getRoleWithRetry();
    }
    
    return role;
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
                  Text('Setting up your profile...'),
                ],
              ),
            ),
          );
        }

        final String? role = roleSnapshot.data;

        if (role == 'admin') {
          return const AdminDashboardScreen();
        } else if (role == 'instructor') {
          return const InstructorDashboardScreen();
        } else if (role == 'student') {
          return const StudentDashboardScreen();
        } else {
          // If still null after retries, allow retry via UI or Logout
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
                        // Reset retry count and fetch again
                        _retryCount = 0;
                        _fetchRole();
                      },
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await widget.authService.signOut();
                        // Navigation handled by StreamBuilder in parent
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
