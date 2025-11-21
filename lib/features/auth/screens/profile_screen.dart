import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _contactController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _contactController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  // Pre-fill controllers
                  userAsyncValue.whenData((user) {
                    if (user != null) {
                      _fullNameController.text = user.fullName;
                      _contactController.text = user.contact;
                    }
                  });
                });
              },
            ),
        ],
      ),
      body: userAsyncValue.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));

          // If not editing, show display view
          if (!_isEditing) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileItem('Full Name', user.fullName),
                  const Divider(),
                  _buildProfileItem('Email', user.email),
                  const Divider(),
                  _buildProfileItem('Contact', user.contact.isEmpty ? 'Not set' : user.contact),
                  const Divider(),
                  _buildProfileItem('Role', user.role.toString().split('.').last.toUpperCase()),
                ],
              ),
            );
          }

          // Edit View
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(labelText: 'Contact Number'),
                  ),
                  const SizedBox(height: 24),
                  if (authState.isLoading)
                    const CircularProgressIndicator()
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await ref.read(authControllerProvider.notifier).updateProfile(
                                  uid: user.uid,
                                  fullName: _fullNameController.text.trim(),
                                  contact: _contactController.text.trim(),
                                );
                                
                                if (mounted) {
                                  setState(() {
                                    _isEditing = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profile updated successfully')),
                                  );
                                }
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
