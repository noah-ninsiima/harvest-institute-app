import 'package:flutter/material.dart';
import '../../shared/models/moodle_course_model.dart';

class CourseDetailScreen extends StatelessWidget {
  final MoodleCourseModel course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.fullname),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              course.fullname,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Course ID: ${course.id}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            const Text('Course content coming soon...'),
          ],
        ),
      ),
    );
  }
}

