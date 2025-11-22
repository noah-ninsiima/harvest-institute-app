import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/controllers/auth_controller.dart'; // For user ID
import '../../shared/models/course.dart';

class InstructorCoursesScreen extends ConsumerWidget {
  const InstructorCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) return const Center(child: Text("Not Logged In"));

    return Scaffold(
      appBar: AppBar(title: const Text("My Courses")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('instructorId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final courses = snapshot.data!.docs;
          
          if (courses.isEmpty) return const Center(child: Text("No courses assigned yet."));

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final doc = courses[index];
              final data = doc.data() as Map<String, dynamic>;
              
               // Safe mapping
              final course = Course(
                courseId: doc.id,
                name: data['title'] ?? data['name'] ?? 'Unnamed',
                duration: data['duration'] ?? '',
                tuition: (data['tuition'] ?? 0.0).toDouble(),
                instructorId: data['instructorId'] ?? '',
                createdAt: DateTime.now(), // Simplified
              );

              return Card(
                child: ListTile(
                  title: Text(course.name),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateAssignmentScreen(courseId: course.courseId, courseName: course.name),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CreateAssignmentScreen extends StatefulWidget {
  final String courseId;
  final String courseName;
  
  const CreateAssignmentScreen({super.key, required this.courseId, required this.courseName});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _createAssignment() async {
    if (_formKey.currentState!.validate() && _dueDate != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('assignments').add({
          'courseId': widget.courseId,
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'dueDate': Timestamp.fromDate(_dueDate!),
          'createdAt': FieldValue.serverTimestamp(),
          'maxPoints': 100, // Default
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment Created!')));
          Navigator.pop(context);
        }
      } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
         if (mounted) setState(() => _isLoading = false);
      }
    } else if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a due date')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Assignment: ${widget.courseName}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Assignment Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(_dueDate == null 
                    ? 'No Due Date Selected' 
                    : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}'),
                  const Spacer(),
                  TextButton(onPressed: _pickDate, child: const Text('Select Date')),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAssignment,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Create Assignment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
