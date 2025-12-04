import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SubmissionListScreen extends StatelessWidget {
  final String assignmentId;

  const SubmissionListScreen({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submissions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('submissions')
            .where('assignment_id', isEqualTo: assignmentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final submissions = snapshot.data!.docs;

          if (submissions.isEmpty) {
            return const Center(child: Text('No submissions yet.'));
          }

          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final data = submissions[index].data() as Map<String, dynamic>;
              final submissionDate = (data['submission_date'] as Timestamp?)?.toDate();

              return ListTile(
                title: Text('Student ID: ${data['user_id']}'), // Ideally fetch student name
                subtitle: Text(submissionDate != null 
                  ? 'Submitted: ${DateFormat.yMMMd().add_jm().format(submissionDate)}' 
                  : 'No date'),
                trailing: const Icon(Icons.file_present),
                onTap: () {
                  // TODO: Open submission details/file
                },
              );
            },
          );
        },
      ),
    );
  }
}
