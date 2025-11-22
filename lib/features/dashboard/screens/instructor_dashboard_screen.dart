import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/profile_screen.dart';

class InstructorDashboardScreen extends ConsumerWidget {
  const InstructorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
        title: const Text('Instructor Dashboard'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(authControllerProvider.notifier).signOut(ref, context);
        },
        child: const Icon(Icons.logout),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: const Center(
        child: Text('Welcome Instructor!'),
      ),
    );
  }
}
