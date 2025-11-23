import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'create_assignment_screen.dart';
import 'submission_list_screen.dart';

class AssignmentListScreen extends StatelessWidget {
  const AssignmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Assignments')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .where('instructor_id', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final assignments = snapshot.data!.docs;

          if (assignments.isEmpty) {
            return const Center(child: Text('No assignments created yet.'));
          }

          return ListView.builder(
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final doc = assignments[index];
              final data = doc.data() as Map<String, dynamic>;
              final dueDate = (data['due_date'] as Timestamp?)?.toDate();

              return ListTile(
                title: Text(data['title'] ?? 'Untitled'),
                subtitle: Text(dueDate != null ? 'Due: ${DateFormat.yMMMd().format(dueDate)}' : 'No due date'),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    const PopupMenuItem(value: 'view_submissions', child: Text('View Submissions')),
                  ],
                  onSelected: (value) {
                    if (value == 'view_submissions') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SubmissionListScreen(assignmentId: doc.id)),
                      );
                    } else if (value == 'delete') {
                      FirebaseFirestore.instance.collection('assignments').doc(doc.id).delete();
                    } else if (value == 'edit') {
                      // TODO: Navigate to edit screen (reuse create screen with arguments)
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateAssignmentScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
