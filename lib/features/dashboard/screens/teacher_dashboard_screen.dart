import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../instructor/providers/instructor_providers.dart';
import '../../shared/widgets/side_menu_drawer.dart';
import '../../shared/models/moodle_course_model.dart';
import '../../instructor/screens/instructor_course_detail_screen.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final userAsync =
        ref.watch(authControllerProvider); // Current Moodle Profile
    final coursesAsync = ref.watch(instructorCoursesProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
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
              await ref
                  .read(authControllerProvider.notifier)
                  .signOut(ref, context);
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
            // Welcome Header (Matching Student Dashboard)
            userAsync.when(
              data: (user) => Text(
                'Welcome, ${user?.firstname ?? "Instructor"}!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              loading: () => const Text('Welcome, Instructor!'),
              error: (_, __) => const Text('Welcome, Instructor!'),
            ),
            const SizedBox(height: 24),

            // Courses Section
            Text(
              'My Courses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Failed to load courses. Please pull to refresh.',
                  style: TextStyle(color: Colors.red[300]),
                ),
              ),
              data: (courses) {
                if (courses.isEmpty) {
                  return const Center(
                    child: Text('No courses assigned.'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    return InstructorCourseCard(course: courses[index]);
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

class InstructorCourseCard extends ConsumerStatefulWidget {
  final MoodleCourseModel course;

  const InstructorCourseCard({super.key, required this.course});

  @override
  ConsumerState<InstructorCourseCard> createState() =>
      _InstructorCourseCardState();
}

class _InstructorCourseCardState extends ConsumerState<InstructorCourseCard> {
  int? _studentCount;
  int? _submissionCount;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourseStats();
  }

  Future<void> _fetchCourseStats() async {
    if (!mounted) return;

    final service = ref.read(moodleInstructorServiceProvider);
    final token = await ref.read(moodleAuthServiceProvider).getStoredToken();

    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      // 1. Fetch Participants
      final participants =
          await service.getEnrolledUsers(token, widget.course.id);

      // 2. Fetch Assignments & Submissions
      final assignments = await service.getAssignments(token, widget.course.id);
      int submissions = 0;

      if (assignments.isNotEmpty) {
        final assignmentIds =
            assignments.map<int>((a) => a['id'] as int).toList();
        final allSubmissions =
            await service.getSubmissions(token, assignmentIds);
        // Count submissions that are 'submitted'
        submissions =
            allSubmissions.where((s) => s['status'] == 'submitted').length;
      }

      if (mounted) {
        setState(() {
          _studentCount = participants.length;
          _submissionCount = submissions;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats for course ${widget.course.id}: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  InstructorCourseDetailScreen(course: widget.course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.class_,
                        color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.fullname,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.course.shortname,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _loading
                  ? const Center(child: LinearProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, Icons.group,
                            '${_studentCount ?? 0}', 'Students'),
                        _buildStatItem(context, Icons.assignment_turned_in,
                            '${_submissionCount ?? 0}', 'Submissions'),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
