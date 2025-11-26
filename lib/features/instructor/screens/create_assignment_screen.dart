import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCourseId;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _saveAssignment() async {
    if (_formKey.currentState!.validate() && _selectedCourseId != null && _dueDate != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('assignments').add({
          'course_id': _selectedCourseId,
          'instructor_id': FirebaseAuth.instance.currentUser!.uid,
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'due_date': Timestamp.fromDate(_dueDate!),
          'created_at': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment saved!')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a course')));
    } else if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a due date')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Assignment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    // Correct field name based on Course model: 'instructorId' not 'instructor_id'
                    .where('instructorId', isEqualTo: user?.uid) 
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text("Error loading courses: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                    );
                  }
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  
                  final courses = snapshot.data!.docs;
                  
                  if (courses.isEmpty) {
                     return const Padding(
                       padding: EdgeInsets.only(bottom: 16.0),
                       child: Text("No courses found for this instructor.", style: TextStyle(color: Colors.red)),
                     );
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    decoration: const InputDecoration(labelText: 'Select Course'),
                    items: courses.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Unnamed Course'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCourseId = val),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_dueDate == null 
                  ? 'Pick Due Date' 
                  : 'Due: ${DateFormat.yMMMd().format(_dueDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.grey)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAssignment,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Save Assignment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
