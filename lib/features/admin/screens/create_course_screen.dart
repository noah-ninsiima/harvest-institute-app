import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/course.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _tuitionController = TextEditingController();
  String _selectedSchoolCategory = 'Leadership & Ministry'; // Default
  bool _isLoading = false;

  final List<String> _schoolCategories = [
    'Leadership & Ministry',
    'Practical Business',
    'Technology',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _tuitionController.dispose();
    super.dispose();
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final courseId = 'course_${DateTime.now().millisecondsSinceEpoch}';
      final newCourse = Course(
        courseId: courseId,
        name: _nameController.text.trim(),
        duration: _durationController.text.trim(),
        tuition: double.tryParse(_tuitionController.text.trim()) ?? 0.0,
        instructorId: 'tbd', // Placeholder, potentially selectable later
        createdAt: DateTime.now(),
        schoolCategory: _selectedSchoolCategory,
      );

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .set(newCourse.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating course: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Course'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Course Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSchoolCategory,
                decoration: const InputDecoration(labelText: 'School Category'),
                items: _schoolCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSchoolCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration (e.g., 12 weeks)'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter duration' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tuitionController,
                decoration: const InputDecoration(labelText: 'Tuition Cost'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter tuition';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _createCourse,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
