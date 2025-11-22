import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../shared/models/course.dart';
import '../services/payment_service.dart';

final paymentServiceProvider = Provider((ref) => PaymentService());

class CourseMarketplaceScreen extends ConsumerWidget {
  const CourseMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Marketplace'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle potential data mismatch (field names)
          final courses = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Map Firestore 'title' to 'name' if needed, or ensure Course model matches Firestore
            // Based on AdminDashboard, we used 'title' and 'description'. 
            // But Course model uses 'name' and 'duration'. 
            // Let's adapt data to Course model or use dynamic map.
            
            // HACK: Ensure ID is set
            data['courseId'] = doc.id;
            
            // Mapping fields manually to match AdminDashboard creation vs Course Model
            return Course(
              courseId: doc.id,
              name: data['title'] ?? data['name'] ?? 'Unnamed Course',
              duration: data['duration'] ?? 'N/A',
              tuition: (data['tuition'] ?? data['price'] ?? 0.0).toDouble(),
              instructorId: data['instructorId'] ?? '',
              createdAt: data['createdAt'] != null 
                  ? (data['createdAt'] as Timestamp).toDate() 
                  : DateTime.now(),
            );
          }).toList();

          if (courses.isEmpty) {
            return const Center(child: Text('No courses available.'));
          }

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(course.name),
                  subtitle: Text('Tuition: \$${course.tuition}'),
                  trailing: ElevatedButton(
                    onPressed: () => _showCourseDetails(context, ref, course),
                    child: const Text('View'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCourseDetails(BuildContext context, WidgetRef ref, Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(course.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Duration: ${course.duration}'),
            Text('Instructor ID: ${course.instructorId}'), // Ideally fetch name
            const SizedBox(height: 16),
            Text('Price: \$${course.tuition}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showPaymentDialog(context, ref, course),
                child: const Text('Enroll Now'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, Course course) {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(course: course),
    );
  }
}

class PaymentDialog extends ConsumerStatefulWidget {
  final Course course;
  const PaymentDialog({super.key, required this.course});

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  String _selectedMethod = 'Card';
  bool _isLoading = false;

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);
    final user = ref.read(authStateChangesProvider).value;
    
    if (user == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to enroll.')),
      );
      Navigator.pop(context); // Close dialog
      return;
    }

    try {
      await ref.read(paymentServiceProvider).processEnrollment(
        userId: user.uid,
        courseId: widget.course.courseId,
        amount: widget.course.tuition,
        paymentMethod: _selectedMethod,
      );
      
      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close details sheet (optional, but good UX)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment Successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrollment Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Enrollment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Course: ${widget.course.name}'),
          Text('Amount: \$${widget.course.tuition}'),
          const SizedBox(height: 16),
          const Text('Select Payment Method:'),
          RadioListTile<String>(
            title: const Text('Card'),
            value: 'Card',
            groupValue: _selectedMethod,
            onChanged: (value) => setState(() => _selectedMethod = value!),
          ),
          RadioListTile<String>(
            title: const Text('Mobile Money'),
            value: 'Mobile Money',
            groupValue: _selectedMethod,
            onChanged: (value) => setState(() => _selectedMethod = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _processPayment,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Text('Pay & Enroll'),
        ),
      ],
    );
  }
}
