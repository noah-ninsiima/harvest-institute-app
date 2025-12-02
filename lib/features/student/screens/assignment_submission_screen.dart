import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/moodle_student_models.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../student/providers/student_providers.dart';

class AssignmentSubmissionScreen extends ConsumerStatefulWidget {
  final MoodleAssignmentModel assignment;

  const AssignmentSubmissionScreen({super.key, required this.assignment});

  @override
  ConsumerState<AssignmentSubmissionScreen> createState() => _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState extends ConsumerState<AssignmentSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authService = ref.read(moodleAuthServiceProvider);
      final studentService = ref.read(moodleStudentServiceProvider);

      final token = await authService.getStoredToken();
      if (token == null) throw Exception('Authentication token not found');

      await studentService.saveSubmission(
        token,
        widget.assignment.id,
        _urlController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission Received'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the previous screen (assignments list)
        // We assume the previous screen watches a provider we can invalidate, or just pop with result
        // Invalidating the specific provider family member would be ideal if we had the courseId.
        // For now, we just pop. The detail screen might need to auto-refresh or we can return true.
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Assignment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.assignment.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Due Date: ${DateTime.fromMillisecondsSinceEpoch(widget.assignment.dueDate * 1000).toString().split(' ')[0]}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Text(
                'Submission URL',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  hintText: 'https://docs.google.com/...',
                  labelText: 'Paste your link here',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a URL';
                  }
                  // Simple URL validation
                  if (!Uri.parse(value).isAbsolute) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAssignment,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Assignment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

