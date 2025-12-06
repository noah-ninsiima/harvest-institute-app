import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/moodle_course_model.dart';
import '../providers/instructor_providers.dart';
import 'submission_list_screen.dart';

class InstructorCourseDetailScreen extends ConsumerStatefulWidget {
  final MoodleCourseModel course;

  const InstructorCourseDetailScreen({super.key, required this.course});

  @override
  ConsumerState<InstructorCourseDetailScreen> createState() =>
      _InstructorCourseDetailScreenState();
}

class _InstructorCourseDetailScreenState
    extends ConsumerState<InstructorCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.fullname),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [
            Tab(text: 'Students Enrolled', icon: Icon(Icons.people)),
            Tab(text: 'Assignments Submitted', icon: Icon(Icons.assignment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StudentsTab(courseId: widget.course.id),
          _AssignmentsTab(courseId: widget.course.id),
        ],
      ),
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  final int courseId;

  const _StudentsTab({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrolledStudentsAsync = ref.watch(courseEnrolledUsersProvider(courseId));

    return enrolledStudentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load students: $err'),
          ],
        ),
      ),
      data: (students) {
        if (students.isEmpty) {
          return const Center(child: Text('No students enrolled.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            // Moodle often returns various fields, try to extract meaningful ones
            final fullName = student['fullname'] ?? '${student['firstname']} ${student['lastname']}' ?? 'Unknown';
            final email = student['email'] ?? 'No Email';
            final profileUrl = student['profileimageurl'] ?? student['profileimageurlsmall'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
                  backgroundColor: Colors.teal.withOpacity(0.2),
                  child: profileUrl == null ? Text(fullName[0].toUpperCase()) : null,
                ),
                title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(email),
              ),
            );
          },
        );
      },
    );
  }
}

class _AssignmentsTab extends ConsumerWidget {
  final int courseId;

  const _AssignmentsTab({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(courseAssignmentsProvider(courseId));

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (assignments) {
        if (assignments.isEmpty) {
          return const Center(child: Text('No assignments found for this course.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            final name = assignment['name'] ?? 'Untitled Assignment';
            final dueDateVal = assignment['duedate'];
            String dueDate = 'No Due Date';
            if (dueDateVal != null && dueDateVal is int && dueDateVal > 0) {
               dueDate = DateTime.fromMillisecondsSinceEpoch(dueDateVal * 1000).toString().split(' ')[0];
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment_outlined, color: Colors.orange),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Due: $dueDate'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                   // Navigate to Submissions List for this Assignment
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) => SubmissionListScreen(
                         assignmentId: assignment['id'].toString(), // Use string for now as per existing screen
                         assignmentName: name,
                       ),
                     ),
                   );
                },
              ),
            );
          },
        );
      },
    );
  }
}
