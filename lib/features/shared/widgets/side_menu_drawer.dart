import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/profile_screen.dart';

class SideMenuDrawer extends ConsumerWidget {
  const SideMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          userAsync.when(
            data: (user) {
              if (user == null) {
                return _buildGuestHeader();
              }
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A2035), // Matches primaryNavy
                ),
                accountName: Text(
                  user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFFF5F5F5),
                  ),
                ),
                accountEmail: Text(
                  user.email.isNotEmpty ? user.email : user.username,
                  style: const TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: (user.userpictureurl != null && user.userpictureurl!.isNotEmpty)
                      ? NetworkImage(user.userpictureurl!)
                      : null,
                  child: (user.userpictureurl == null || user.userpictureurl!.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Color(0xFF1A2035))
                      : null,
                ),
              );
            },
            loading: () => const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1A2035)),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
            error: (err, stack) => _buildGuestHeader(),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context); // Close drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          // Add more menu items here
        ],
      ),
    );
  }

  Widget _buildGuestHeader() {
    return const DrawerHeader(
      decoration: BoxDecoration(
        color: Color(0xFF1A2035),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Harvest Institute',
            style: TextStyle(color: Color(0xFFF5F5F5), fontSize: 24),
          ),
          SizedBox(height: 8),
          Text(
            'Guest',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
