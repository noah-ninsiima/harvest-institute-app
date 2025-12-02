import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/controllers/auth_controller.dart';

// Local provider for Firestore user data
final userProvider = StreamProvider.autoDispose<DocumentSnapshot>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // Controllers
  final _fullNameController = TextEditingController();
  final _contactController = TextEditingController();
  
  bool _isUpdating = false;
  bool _isInitialized = false;
  
  // Moodle Status
  String _moodleStatus = 'Checking Moodle connection...';

  @override
  void initState() {
    super.initState();
    // Trigger Moodle fetch in background without blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMoodleProfile();
    });
  }

  Future<void> _fetchMoodleProfile() async {
    // Defensive: Ensure ref is still valid
    if (!mounted) return;

    try {
      final authService = ref.read(moodleAuthServiceProvider);
      final token = await authService.getStoredToken();
      
      if (token != null) {
        // Fallback Logic: Wrap Moodle call in try-catch
        // If it fails, we just show Firestore data
        try {
          await authService.getUserProfile(token);
          if (mounted) {
            setState(() {
              _moodleStatus = 'Connected to Moodle';
            });
          }
        } catch (e) {
           debugPrint('Moodle Profile API Error: $e');
           if (mounted) {
             setState(() {
               _moodleStatus = 'Moodle Sync Failed (Showing Local Data)';
             });
           }
        }
      } else {
         if (mounted) {
          setState(() {
            _moodleStatus = 'Not connected to Moodle';
          });
        }
      }
    } catch (e) {
      debugPrint('Moodle Service Error: $e');
      if (mounted) {
        setState(() {
          _moodleStatus = 'Service Error (Showing Local Data)';
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fullName': _fullNameController.text.trim(), // Ensure field name matches UserModel
          'contact': _contactController.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        data: (snapshot) {
          if (!snapshot.exists) return const Center(child: Text('User data not found in Firestore.'));
          
          final data = snapshot.data() as Map<String, dynamic>;
          // Fetch current values from Firestore
          final fullName = data['fullName'] ?? data['full_name'] ?? ''; // Handle both cases
          final email = data['email'] ?? 'N/A';
          final role = data['role'] ?? 'N/A';
          final contact = data['contact'] ?? '';

          // Initialize controllers only once to prevent overwriting while editing
          if (!_isInitialized) {
            _fullNameController.text = fullName;
            _contactController.text = contact;
            _isInitialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 8),
                  // Show Moodle Status
                  Text(
                    _moodleStatus,
                    style: TextStyle(
                      color: _moodleStatus.contains('Failed') || _moodleStatus.contains('Error') 
                          ? Colors.red 
                          : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Editable Full Name
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Read-Only Email
                  TextFormField(
                    initialValue: email,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.black12,
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Read-Only Role
                  TextFormField(
                    initialValue: role.toString().toUpperCase(),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      filled: true,
                      fillColor: Colors.black12,
                      prefixIcon: Icon(Icons.security),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Editable Contact
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact / Phone',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _updateProfile,
                      child: _isUpdating 
                        ? const CircularProgressIndicator() 
                        : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}
