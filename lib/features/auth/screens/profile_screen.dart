import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading profile: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not logged in.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (user.userpictureurl != null &&
                          user.userpictureurl!.isNotEmpty)
                      ? NetworkImage(user.userpictureurl!)
                      : null,
                  child: (user.userpictureurl == null ||
                          user.userpictureurl!.isEmpty)
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 24),
                _buildProfileField('First Name', user.firstname),
                const SizedBox(height: 16),
                _buildProfileField('Last Name', user.lastname),
                const SizedBox(height: 16),
                _buildProfileField('Username', user.username),
                const SizedBox(height: 16),
                _buildProfileField('Email', user.email),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(authControllerProvider.notifier)
                          .checkAuthStatus();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Profile'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.black12,
      ),
    );
  }
}
