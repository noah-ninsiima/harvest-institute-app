import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../auth/widgets/role_check_wrapper.dart';
import '../../student/screens/course_list_screen.dart';
import '../../shared/widgets/side_menu_drawer.dart'; // Import SideMenuDrawer

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final AuthService _authService = AuthService();
  // We can control the drawer using the Scaffold's context if we don't provide a leading widget, 
  // or explicit key if we want to open it from a custom button.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        // Leading icon to open drawer (User Profile Icon)
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
      drawer: const SideMenuDrawer(), // Ensure this is present
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Student!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('QR Scanner coming soon!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.payment,
                    label: 'Pay Tuition',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment module coming soon!')),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Schools',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SchoolCategoryCard(
              title: 'Leadership & Ministry',
              color: Colors.purple.shade700,
              icon: Icons.church,
              onTap: () => _navigateToCourseList(context, 'Leadership & Ministry'),
            ),
            const SizedBox(height: 16),
            SchoolCategoryCard(
              title: 'Practical Business',
              color: Colors.blue.shade700,
              icon: Icons.business_center,
              onTap: () => _navigateToCourseList(context, 'Practical Business'),
            ),
            const SizedBox(height: 16),
            SchoolCategoryCard(
              title: 'Technology',
              color: Colors.teal.shade700,
              icon: Icons.computer,
              onTap: () => _navigateToCourseList(context, 'Technology'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCourseList(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseListScreen(category: category),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class SchoolCategoryCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const SchoolCategoryCard({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Icon(icon, size: 40, color: Colors.white),
                const SizedBox(width: 24),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
