import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../screens/login_screen.dart';
import '../../dashboard/screens/student_dashboard_screen.dart';
import '../../dashboard/screens/instructor_dashboard_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../shared/models/user_model.dart';

class RoleCheckWrapper extends ConsumerWidget {
  const RoleCheckWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final userProfile = ref.watch(userProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();
        
        return userProfile.when(
          data: (userModel) {
            if (userModel == null) return const Scaffold(body: Center(child: Text("User data not found")));
            
            switch (userModel.role) {
              case UserRole.student:
                return const StudentDashboardScreen();
              case UserRole.instructor:
                return const InstructorDashboardScreen();
              case UserRole.admin:
                return const AdminDashboardScreen();
            }
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
