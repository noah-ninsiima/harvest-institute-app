import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/firestore_service.dart';

class AttendanceScanScreen extends ConsumerStatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  ConsumerState<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends ConsumerState<AttendanceScanScreen> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _processCode(String scannedValue) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Format expected: courseId:YYYY-MM-DD (e.g., 101:2025-12-06 or BAT01:2025-12-06)
      final parts = scannedValue.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid QR Code Format');
      }

      // Support both int IDs and String shortnames
      dynamic courseId;
      final int? parsedId = int.tryParse(parts[0]);
      if (parsedId != null) {
        courseId = parsedId;
      } else {
        // If it's not a number, treat as shortname string (e.g., "BAT01")
        if (parts[0].trim().isEmpty) throw Exception('Invalid Course ID');
        courseId = parts[0].trim();
      }

      final String qrDate = parts[1];
      final String today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD

      if (qrDate != today) {
        throw Exception('Code expired or invalid date ($qrDate)');
      }

      // Get Moodle User ID
      final authState = ref.read(authControllerProvider).value;
      if (authState == null) {
        throw Exception('User not authenticated');
      }

      // Call Firestore Service
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.markAttendance(
        studentId: 'moodle_${authState.userid}',
        studentName: authState.fullName,
        courseId: courseId,
        date: today,
      );

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Attendance marked successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // Return to dashboard
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Reset processing to allow scanning again
                  setState(() {
                    _isProcessing = false;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted && _isProcessing) {
         setState(() {
           _isProcessing = false;
         });
      }
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? scannedValue = barcodes.first.rawValue;
    if (scannedValue == null || scannedValue.isEmpty) return;
    
    await _processCode(scannedValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Attendance QR'),
        actions: [
          // Fallback for emulator testing
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: () {
              _showManualEntryDialog(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'Align QR Code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, backgroundColor: Colors.black54),
            ),
                    ),
                  ],
                ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Entry (Dev Only)'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Enter Code (courseId:YYYY-MM-DD)',
            hintText: 'e.g. 101:2025-12-06',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processCode(textController.text.trim());
            },
            child: const Text('Submit'),
            ),
        ],
      ),
    );
  }
}
