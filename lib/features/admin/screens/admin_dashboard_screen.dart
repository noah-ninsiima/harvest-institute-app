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
  String? _selectedInstructorId;
  String? _selectedInstructorName;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCourse() async {
    if (_formKey.currentState!.validate() && _selectedInstructorId != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create course in Firestore
        await FirebaseFirestore.instance.collection('courses').add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'instructorId': _selectedInstructorId,
          'instructorName': _selectedInstructorName ?? 'Unknown Instructor',
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
            _selectedInstructorId = null;
            _selectedInstructorName = null;
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
    } else if (_selectedInstructorId == null) {
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

  // Task 2: Admin Dashboard Enhancements (Edit Instructor)
  Future<void> _editCourseInstructor(String courseId, String currentInstructorId) async {
    String? newInstructorId = currentInstructorId;
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Instructor'),
          content: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'instructor')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              
              List<UserModel> instructors = snapshot.data!.docs
                  .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();
              
              // Ensure initial value is valid or null
              if (newInstructorId != null && !instructors.any((i) => i.uid == newInstructorId)) {
                newInstructorId = null;
              }

              return DropdownButtonFormField<String>(
                value: newInstructorId,
                items: instructors.map((i) => DropdownMenuItem(
                  value: i.uid,
                  child: Text(i.fullName),
                )).toList(),
                onChanged: (val) {
                   newInstructorId = val;
                },
                decoration: const InputDecoration(labelText: 'Select Instructor'),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                 if (newInstructorId != null && newInstructorId != currentInstructorId) {
                    // Fetch name for the selected ID
                    // We can do a quick lookup or just update ID and let UI handle name if it fetches,
                    // but our Course model stores name. So we should probably fetch it.
                    // For simplicity/speed in dialog, we update.
                    // Ideally, we should find the name from the list above, but 'newInstructorId' is just local here.
                    // We will do a transactional update or just update ID.
                    // Let's update ID and Name.
                    
                    final instructorDoc = await FirebaseFirestore.instance.collection('users').doc(newInstructorId).get();
                    final instructorName = instructorDoc.data()?['fullName'] ?? 'Unknown';

                    await FirebaseFirestore.instance.collection('courses').doc(courseId).update({
                      'instructorId': newInstructorId,
                      'instructorName': instructorName,
                    });
                    
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Instructor Updated')));
                 }
                 if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(adminNavIndexProvider);

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
        title: Text(selectedIndex == 0 ? 'Admin Dashboard' : 'Manage Users'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(adminNavIndexProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(authControllerProvider.notifier).signOut(ref, context);
        },
        child: const Icon(Icons.logout),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
                            if (_selectedInstructorId != null) {
                              final instructorExists = instructors.any((i) => i.uid == _selectedInstructorId);
                              if (!instructorExists) {
                                // Safe handle
                              }
                            }

                            String? dropdownValue = _selectedInstructorId;
                            if (dropdownValue != null && !instructors.any((i) => i.uid == dropdownValue)) {
                              dropdownValue = null;
                            }

                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Instructor',
                                border: OutlineInputBorder(),
                              ),
                              value: dropdownValue,
                              items: instructors.map((instructor) {
                                return DropdownMenuItem(
                                  value: instructor.uid,
                                  child: Text(instructor.fullName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedInstructorId = value;
                                  if (value != null) {
                                    try {
                                      final selectedInstructor = instructors.firstWhere((i) => i.uid == value);
                                      _selectedInstructorName = selectedInstructor.fullName;
                                    } catch (e) {
                                      _selectedInstructorName = null;
                                    }
                                  } else {
                                    _selectedInstructorName = null;
                                  }
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
              const SizedBox(height: 30),
              const Text(
                'Existing Courses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // List of existing courses to edit
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('courses').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  
                  final courses = snapshot.data!.docs;
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final data = courses[index].data() as Map<String, dynamic>;
                      final courseId = courses[index].id;
                      final title = data['title'] ?? 'Untitled';
                      final instructorName = data['instructorName'] ?? 'Unknown';
                      final instructorId = data['instructorId'] ?? '';
                      
                      return Card(
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text('Instructor: $instructorName'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editCourseInstructor(courseId, instructorId),
                          ),
                        ),
                      );
                    },
                  );
                },
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
