import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _downloadStatus = '';

  Future<void> _exportEnrollments() async {
    setState(() {
      _downloadStatus = 'Generating export...';
    });

    final User? currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('Export initiated. Current user: ${currentUser?.uid ?? "No user"}');
    if (currentUser == null) {
      setState(() {
        _downloadStatus = 'Error: No user logged in. Please re-authenticate.';
      });
      return;
    }

    try {
      // Call the Firebase Cloud Function
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('exportEnrollmentsToCsv');
      final HttpsCallableResult result = await callable.call();

      final String? downloadUrl = result.data?['downloadUrl'];

      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        // Launch the URL to start the download
        if (await canLaunchUrl(Uri.parse(downloadUrl))) {
          await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
          setState(() {
            _downloadStatus = 'Export generated. Download should start shortly.';
          });
        } else {
          setState(() {
            _downloadStatus = 'Could not launch download URL.';
          });
          debugPrint('Could not launch URL: $downloadUrl');
        }
      } else {
        setState(() {
          _downloadStatus = 'No download URL received.';
        });
        debugPrint('No download URL received from function.');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function Error: code=${e.code}, message=${e.message}, details=${e.details}');
      setState(() {
        _downloadStatus = 'Export failed: ${e.message}';
      });
    } catch (e) {
      debugPrint('Generic Error during export: $e');
      setState(() {
        _downloadStatus = 'Export failed: An unexpected error occurred.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Reports'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.analytics, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            const Text(
              'Generate Reports',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _exportEnrollments,
              icon: const Icon(Icons.download),
              label: const Text('Export Enrollment Data (CSV)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _downloadStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _downloadStatus.startsWith('Export failed') ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
