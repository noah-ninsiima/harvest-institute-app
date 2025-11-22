import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/course_service.dart';

class CourseMarketplaceScreen extends StatefulWidget {
  const CourseMarketplaceScreen({super.key});

  @override
  State<CourseMarketplaceScreen> createState() => _CourseMarketplaceScreenState();
}

class _CourseMarketplaceScreenState extends State<CourseMarketplaceScreen> {
  final CourseService _courseService = CourseService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('Please log in to view courses.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Marketplace'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _courseService.getCourses(), // Stream all courses
        builder: (context, courseSnapshot) {
          if (courseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (courseSnapshot.hasError) {
            return Center(child: Text('Error: ${courseSnapshot.error}'));
          }
          if (!courseSnapshot.hasData || courseSnapshot.data!.isEmpty) {
            return const Center(child: Text('No courses available.'));
          }

          final List<Map<String, dynamic>> allCourses = courseSnapshot.data!;

          // Now, stream the student's enrollments to filter courses
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _courseService.getStudentEnrollments(currentUser!.uid),
            builder: (context, enrollmentSnapshot) {
              // If enrollments are loading, show loading indicator, or just show courses but maybe disable buttons
              // Better to wait to ensure we don't show enrolled courses as available
              if (enrollmentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (enrollmentSnapshot.hasError) {
                // If there's an error fetching enrollments (e.g. permission), 
                // we should probably still show courses but maybe warn user
                debugPrint('Error fetching enrollments: ${enrollmentSnapshot.error}');
                return Center(child: Text('Error checking enrollments: ${enrollmentSnapshot.error}'));
              }

              final List<String> enrolledCourseIds = enrollmentSnapshot.hasData
                  ? enrollmentSnapshot.data!.map((e) => e['course_id'] as String).toList()
                  : [];

              final List<Map<String, dynamic>> availableCourses = allCourses
                  .where((course) => !enrolledCourseIds.contains(course['id']))
                  .toList();

              if (availableCourses.isEmpty) {
                return const Center(child: Text('You are enrolled in all available courses!'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: availableCourses.length,
                itemBuilder: (context, index) {
                  final course = availableCourses[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['name'] as String,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          Text('Duration: ${course['duration']} weeks'),
                          Text('Tuition: \$${(course['tuition'] as num).toStringAsFixed(2)}'),
                          // Instructor name would require fetching from 'users' collection
                          // For simplicity, we'll just show the instructor_id for now
                          Text('Instructor ID: ${course['instructor_id']}'),
                          const SizedBox(height: 16.0),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _courseService.enrollInCourse(course['id'] as String);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Successfully enrolled in ${course['name']}!')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to enroll: ${e.toString()}')),
                                  );
                                }
                              },
                              child: const Text('Enroll Now'),
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
