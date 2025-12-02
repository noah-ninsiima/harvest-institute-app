import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/profile_screen.dart';
// import '../../auth/widgets/role_check_wrapper.dart'; // Removed unused import
import '../../instructor/repositories/instructor_repository.dart';
import '../../student/screens/qr_scanner_screen.dart';
import '../../shared/models/course.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _pendingGradingCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    // In a real app, you'd probably fetch this from a summary API or aggregate locally
    // For now, we'll simulate checking assignments for grading
    if (currentUser == null) return;

    try {
      // 1. Get Courses for Instructor from Firestore
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('instructorId', isEqualTo: currentUser!.uid)
          .get();

      if (coursesSnapshot.docs.isEmpty) {
        if (mounted) setState(() => _isLoadingStats = false);
        return;
      }

      // 2. For each course, fetch assignments and submissions (Moodle)
      // This can be heavy, so in production consider a dedicated endpoint or caching
      int totalPending = 0;
      final instructorRepo = ref.read(instructorRepositoryProvider);

      // Simplified logic: Just fetching for the first course to show example
      // Iterating all courses might be too slow for initState
      if (coursesSnapshot.docs.isNotEmpty) {
         // Assume we store moodleCourseId in Firestore course doc
         // If not, we might need another way to link
         // For this demo, we'll skip the heavy API call to avoid blocking or errors if data isn't synced
         // and just show a placeholder or mock calculation if needed.
         
         // However, let's try to fetch for at least one if possible
         final firstCourseData = coursesSnapshot.docs.first.data();
         if (firstCourseData.containsKey('moodleId')) {
            final moodleCourseId = firstCourseData['moodleId'];
            if (moodleCourseId != null) {
              final assignments = await instructorRepo.getAssignments(moodleCourseId);
              if (assignments.isNotEmpty) {
                 final ids = assignments.map<int>((a) => a['id'] as int).toList();
                 final submissions = await instructorRepo.getSubmissions(ids);
                 // Count submissions that need grading (status = submitted, no grade)
                 // Moodle structure varies, but usually check 'gradingstatus' or 'grade'
                 totalPending = submissions.where((s) => s['status'] == 'submitted' && (s['gradingstatus'] != 'graded')).length;
              }
            }
         }
      }

      if (mounted) {
        setState(() {
          _pendingGradingCount = totalPending;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  void _handleLogout() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signOut(ref, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Card(
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30,
                      child: Icon(Icons.school, size: 30, color: Colors.teal),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back,',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          currentUser?.displayName ?? 'Instructor',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions (Attendance & Grading)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.qr_code_scanner,
                    title: 'Attendance',
                    value: 'Scan',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.assignment_turned_in,
                    title: 'Pending Grading',
                    value: _isLoadingStats ? '...' : _pendingGradingCount.toString(),
                    color: Colors.blue,
                    onTap: () {
                      // Navigate to Grading/Submissions Screen
                      // For now, just show a message or implement list navigation later
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Navigate to Submissions List')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // My Courses Section
            const Text(
              'My Courses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCoursesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('instructorId', isEqualTo: currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No courses assigned.')),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final course = Course.fromMap(data); // Assuming Course model exists

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book, color: Colors.teal),
                ),
                title: Text(course.name),
                subtitle: Text('${course.schoolCategory} • ${course.duration}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to Course Details for Instructor
                  // e.g., CourseManagementScreen
                },
              ),
            );
          },
        );
      },
    );
  }
}

