import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_provider.dart';
import '../../shared/models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isInitialized = false;

  // Colors from requirements
  final Color _darkNavy = const Color(0xFF0F172A);
  final Color _tealAccent = const Color(0xFF00BFA5);

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeControllers(UserModel user) {
    if (_isInitialized) return;
    _fullNameController.text = user.fullName;
    _usernameController.text = user.username;
    _emailController.text = user.email;
    _phoneController.text = user.contact;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider);

    // Listen to profile actions state for loading/error feedback
    ref.listen(profileProvider, (previous, next) {
      next.when(
        data: (_) {
          // If we wanted to show success, we could do it here, but it might trigger on initial load too.
          // Ideally we check if previous was loading.
          if (previous is AsyncLoading && !previous.hasError) {
            // This logic is a bit brittle with AsyncValue generic types.
            // Keeping it simple: error handling here. Success handling in button callbacks if possible,
            // or just rely on UI updates.
          }
        },
        loading: () {},
        error: (e, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: _darkNavy,
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: userAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: Colors.white))),
        data: (user) {
          if (user == null) {
            return const Center(
                child: Text('User not found',
                    style: TextStyle(color: Colors.white)));
          }
          _initializeControllers(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(user),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                  const SizedBox(height: 16),
                  _buildChangePasswordButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    final imageProvider = (user.photoUrl != null && user.photoUrl!.isNotEmpty)
        ? NetworkImage(user.photoUrl!)
        : null;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _tealAccent, width: 2),
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[800],
            backgroundImage: imageProvider as ImageProvider?,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              ref.read(profileProvider.notifier).uploadImage();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _tealAccent,
                shape: BoxShape.circle,
                border: Border.all(color: _darkNavy, width: 3),
              ),
              child:
                  const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: readOnly ? Colors.grey : _tealAccent),
        filled: true,
        fillColor: const Color(0xFF1E293B), // Slightly lighter than bg
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: readOnly
                  ? Colors.grey.withOpacity(0.3)
                  : _tealAccent.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _tealAccent, width: 2),
        ),
      ),
      validator: (value) {
        if (!readOnly && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    final isLoading = ref.watch(profileProvider).isLoading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  await ref.read(profileProvider.notifier).updateProfile(
                        username: _usernameController.text,
                        contact: _phoneController.text,
                        fullName: _fullNameController.text,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile updated successfully!')),
                    );
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: _tealAccent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () => _showChangePasswordDialog(),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Change Password',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: currentPasswordController,
                label: 'Current Password',
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: newPasswordController,
                label: 'New Password',
                icon: Icons.lock_reset,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context); // Close dialog first

                          try {
                            await ref
                                .read(profileProvider.notifier)
                                .changePassword(
                                  currentPassword:
                                      currentPasswordController.text,
                                  newPassword: newPasswordController.text,
                                );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Password changed successfully!')),
                              );
                            }
                          } catch (e) {
                            // Error handled by listener
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tealAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Change'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
