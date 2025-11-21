import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/profile_screen.dart';
import '../../shared/models/user_model.dart';

// State provider for the selected bottom nav index
final adminNavIndexProvider = StateProvider<int>((ref) => 0);

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  UserModel? _selectedInstructor;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCourse() async {
    if (_formKey.currentState!.validate() && _selectedInstructor != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create course in Firestore
        await FirebaseFirestore.instance.collection('courses').add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'instructorId': _selectedInstructor!.uid,
          'instructorName': _selectedInstructor!.fullName,
          'createdAt': FieldValue.serverTimestamp(),
          'studentIds': [],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course created successfully!')),
          );
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedInstructor = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating course: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_selectedInstructor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an instructor')),
      );
    }
  }

  Future<void> _promoteUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': 'instructor',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User promoted to Instructor successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error promoting user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(adminNavIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedIndex == 0 ? 'Admin Dashboard' : 'Manage Users'),
        actions: [
           PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              } else if (value == 'logout') {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(adminNavIndexProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _buildCreateCourseView(),
          _buildManageUsersView(),
        ],
      ),
    );
  }

  Widget _buildCreateCourseView() {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Course',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Course Title',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Instructor Dropdown
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'instructor')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            List<UserModel> instructors = snapshot.data!.docs
                                .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
                                .toList();

                            if (instructors.isEmpty) {
                              return const Text('No instructors found. Promote a user first.');
                            }

                            // Check if previously selected instructor is still in the list
                            if (_selectedInstructor != null) {
                              final instructorExists = instructors.any((i) => i.uid == _selectedInstructor!.uid);
                              if (!instructorExists) {
                                _selectedInstructor = null;
                              }
                            }

                            return DropdownButtonFormField<UserModel>(
                              decoration: const InputDecoration(
                                labelText: 'Select Instructor',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedInstructor,
                              items: instructors.map((instructor) {
                                return DropdownMenuItem(
                                  value: instructor,
                                  child: Text(instructor.fullName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedInstructor = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select an instructor';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createCourse,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Create Course'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildManageUsersView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        if (users.isEmpty) {
          return const Center(child: Text('No students found.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(user.fullName),
                subtitle: Text(user.email),
                trailing: ElevatedButton(
                  onPressed: () => _promoteUser(user.uid),
                  child: const Text('Promote to Instructor'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
