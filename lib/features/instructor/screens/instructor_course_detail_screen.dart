import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/shared/models/moodle_course_model.dart';
import '../../../services/moodle_instructor_service.dart';
import '../../../services/moodle_student_service.dart'; // Reuse for getAssignments
import '../../../features/auth/controllers/auth_controller.dart'; // For token

class InstructorCourseDetailScreen extends ConsumerStatefulWidget {
  final MoodleCourseModel course;

  const InstructorCourseDetailScreen({super.key, required this.course});

  @override
  ConsumerState<InstructorCourseDetailScreen> createState() =>
      _InstructorCourseDetailScreenState();
}

class _InstructorCourseDetailScreenState
    extends ConsumerState<InstructorCourseDetailScreen> {
  late MoodleInstructorService _instructorService;
  late MoodleStudentService _studentService;

  Future<int>? _participantsCountFuture;
  Future<List<dynamic>>?
      _assignmentsFuture; // Using dynamic or MoodleAssignmentModel

  @override
  void initState() {
    super.initState();
    _instructorService = MoodleInstructorService();
    _studentService = MoodleStudentService();

    // Trigger fetches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    final token = await ref.read(moodleAuthServiceProvider).getStoredToken();
    if (token != null) {
      setState(() {
        _participantsCountFuture = _instructorService
            .getCourseParticipants(token, widget.course.id)
            .then((list) => list.length);

        // Reusing student service to get assignments list
        _assignmentsFuture =
            _studentService.getAssignments(token, widget.course.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.fullname),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              widget.course.fullname,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Stat Card: Enrolled Students
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Enrolled Students',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    FutureBuilder<int>(
                      future: _participantsCountFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return const Text('Error');
                        }
                        return Text(
                          '${snapshot.data ?? 0} Students',
                          style: Theme.of(context).textTheme.titleLarge,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Assignment List
            Text('Assignments', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: _assignmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error loading assignments: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No assignments found.');
                }

                final assignments = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    // Assuming MoodleAssignmentModel or similar structure from student service
                    return Card(
                      child: ListTile(
                        title: Text(assignment.name),
                        subtitle: Text(
                            'Due: ${DateTime.fromMillisecondsSinceEpoch(assignment.dueDate * 1000).toString().split(' ')[0]}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to SubmissionListScreen (Placeholder)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Navigate to Submissions')),
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
