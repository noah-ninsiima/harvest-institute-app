import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/course_service.dart';

class CourseListScreen extends StatefulWidget {
  final String category;

  const CourseListScreen({super.key, required this.category});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final CourseService _courseService = CourseService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _courseService.getCoursesByCategory(widget.category),
        builder: (context, courseSnapshot) {
          if (courseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (courseSnapshot.hasError) {
            return Center(child: Text('Error: ${courseSnapshot.error}'));
          }
          if (!courseSnapshot.hasData || courseSnapshot.data!.isEmpty) {
            return const Center(child: Text('No courses available in this school.'));
          }

          final List<Map<String, dynamic>> categoryCourses = courseSnapshot.data!;

          // Filter out enrolled courses
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _courseService.getStudentEnrollments(currentUser!.uid),
            builder: (context, enrollmentSnapshot) {
              if (enrollmentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final List<String> enrolledCourseIds = enrollmentSnapshot.hasData
                  ? enrollmentSnapshot.data!.map((e) => e['course_id'] as String).toList()
                  : [];

              final List<Map<String, dynamic>> availableCourses = categoryCourses
                  .where((course) => !enrolledCourseIds.contains(course['id']))
                  .toList();

              if (availableCourses.isEmpty) {
                return const Center(child: Text('You are enrolled in all available courses for this school!'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: availableCourses.length,
                itemBuilder: (context, index) {
                  final course = availableCourses[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['name'] as String,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Duration: ${course['duration']}'),
                          Text('Tuition: \$${(course['tuition'] as num).toStringAsFixed(2)}'),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _courseService.enrollInCourse(course['id'] as String);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Enrolled in ${course['name']}')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Enrollment failed: $e')),
                                    );
                                  }
                                }
                              },
                              child: const Text('Enroll'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
