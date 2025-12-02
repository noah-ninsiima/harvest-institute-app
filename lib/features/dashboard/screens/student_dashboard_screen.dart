import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for direct role check
import 'package:firebase_auth/firebase_auth.dart'; // Needed for current user
import '../../auth/repositories/auth_repository.dart'; // Import AuthRepository
import '../../auth/widgets/role_check_wrapper.dart';
import '../../student/screens/course_detail_screen.dart';
import '../../shared/widgets/side_menu_drawer.dart';
import '../../student/providers/student_providers.dart';
import '../../auth/controllers/auth_controller.dart'; // For currentUserProfileProvider
import '../../student/screens/attendance_scan_screen.dart';

// Make StudentDashboardScreen a ConsumerStatefulWidget to use Ref
class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Task 5: Strict Role Check
    // Ensure we are using the role stored in Firestore as source of truth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyStudentRole();
    });
  }

  Future<void> _verifyStudentRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final role = doc.data()?['role'];
          if (role != 'student') {
            // If strict check fails (e.g. user is actually an instructor but got here),
            // force redirect or logout to prevent unauthorized access/confusion.
            debugPrint('Role Mismatch: User is $role but in Student Dashboard');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Role mismatch detected. Redirecting...'),
                  backgroundColor: Colors.red,
                ),
              );
              // Redirect to RoleCheckWrapper to resolve correct dashboard
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => const RoleCheckWrapper()),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error verifying role: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        leading: IconButton(
          icon: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Use AuthRepository which handles Moodle logout, Firebase logout, and state invalidation
              await ref.read(authRepositoryProvider).signOut();

              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const RoleCheckWrapper()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: const SideMenuDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userAsync.when(
              data: (user) => Text(
                'Welcome, ${user?.firstname ?? "Student"}!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              loading: () => const Text('Welcome, Student!'),
              error: (_, __) => const Text('Welcome, Student!'),
            ),
            const SizedBox(height: 24),

            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceScanScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.payment,
                    label: 'Pay Tuition',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Payment module coming soon!')),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Text(
              'My Courses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // AsyncValue handling for Courses
            enrolledCoursesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 40),
                    const SizedBox(height: 8),
                    Text('Failed to load courses: $err'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.refresh(enrolledCoursesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (courses) {
                if (courses.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(Icons.school_outlined,
                            size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "No in-progress courses",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.book,
                              color: Theme.of(context).primaryColor),
                        ),
                        title: Text(
                          course.fullname,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(course.shortname),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CourseDetailScreen(course: course),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
