import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../auth/widgets/role_check_wrapper.dart';
import '../../instructor/screens/create_assignment_screen.dart';
import '../../instructor/screens/assignment_list_screen.dart';
import '../../shared/models/course.dart'; 
import '../../shared/widgets/side_menu_drawer.dart'; // Import SideMenuDrawer

class InstructorDashboardScreen extends StatefulWidget {
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() => _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        leading: IconButton(
          icon: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); 
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const RoleCheckWrapper()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: const SideMenuDrawer(), // Add Drawer
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Icon(Icons.school, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Welcome, Instructor!', style: TextStyle(fontSize: 24)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateAssignmentScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'New Assignment',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AssignmentListScreen()),
                      );
                    },
                    icon: const Icon(Icons.grade),
                    label: const Text(
                      'Grade Work',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'My Assigned Courses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (currentUser != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .where('instructorId', isEqualTo: currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error loading courses: ${snapshot.error}');
                  }
                  
                  final courses = snapshot.data!.docs;
                  
                  if (courses.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No courses assigned yet.'),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final doc = courses[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final course = Course.fromMap(data);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: ListTile(
                          title: Text(course.name),
                          subtitle: Text('${course.schoolCategory} • ${course.duration}'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                          },
                        ),
                      );
                    },
                  );
                },
              )
            else
              const Text('Please log in to view courses.'),
          ],
        ),
      ),
    );
  }
}
