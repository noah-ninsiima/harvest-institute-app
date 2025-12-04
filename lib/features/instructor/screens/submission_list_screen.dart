import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/instructor_providers.dart';

class SubmissionListScreen extends ConsumerWidget {
  final String assignmentId;
  final String assignmentName;

  const SubmissionListScreen({
    super.key,
    required this.assignmentId,
    this.assignmentName = 'Submissions',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? id = int.tryParse(assignmentId);

    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text(assignmentName)),
        body: const Center(child: Text('Invalid Assignment ID')),
      );
    }

    final submissionsAsync = ref.watch(assignmentSubmissionsProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text(assignmentName)),
      body: submissionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (submissions) {
          if (submissions.isEmpty) {
            return const Center(child: Text('No submissions found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index];
              // Moodle submission structure usually has 'status', 'timemodified', 'userid'
              // Note: 'userid' is returned, but not student name.
              // To get name, we'd ideally map against the student list or fetch profile.
              // For now, showing User ID.

              final status = submission['status'] ?? 'Unknown';
              final timeModified = submission['timemodified'];
              DateTime? submissionDate;
              if (timeModified != null && timeModified is int) {
                submissionDate =
                    DateTime.fromMillisecondsSinceEpoch(timeModified * 1000);
              }

              final userId = submission['userid'] ?? 'Unknown User';

              // Check if there are plugins (files/onlinetext)
              bool hasFile = false;
              if (submission['plugins'] != null) {
                for (var plugin in submission['plugins']) {
                  if (plugin['fileareas'] != null) {
                    hasFile = true;
                    break;
                  }
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: status == 'submitted'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    child: Icon(
                      status == 'submitted'
                          ? Icons.check_circle
                          : Icons.pending,
                      color: status == 'submitted' ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Text('Student ID: $userId'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: $status'),
                      if (submissionDate != null)
                        Text(
                            'Submitted: ${DateFormat.yMMMd().add_jm().format(submissionDate)}'),
                    ],
                  ),
                  trailing: hasFile
                      ? const Icon(Icons.attach_file)
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    // Show details or file
                    // TODO: Implement file download/viewing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Viewing submission details not implemented yet.')),
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
