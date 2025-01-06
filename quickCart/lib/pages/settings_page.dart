import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_service.dart';
import '../auth/login_screen.dart'; // Ensure this path is correct

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService(); // Create an instance of AuthService

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center( // Center the content
          child: SingleChildScrollView( // Allow scrolling if content overflows
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center items vertically
              children: [
                // Title for the Settings Page
                Text(
                  'Settings',
                  style: GoogleFonts.lobster(
                    fontSize: 60, // Adjust font size as needed
                    color: Colors.blueAccent, // Change color if needed
                  ),
                ),
                const SizedBox(height: 70), // Space between title and settings options
                _buildSettingTile(
                  context,
                  title: 'Notifications',
                  icon: Icons.notifications,
                  onTap: () {
                    // Navigate to notification settings
                  },
                ),
                _buildSettingTile(
                  context,
                  title: 'Language',
                  icon: Icons.language,
                  onTap: () {
                    // Navigate to language settings
                  },
                ),
                _buildSettingTile(
                  context,
                  title: 'Log Out',
                  icon: Icons.logout,
                  color: Colors.red,
                  onTap: () async {
                    await authService.signout(); // Call signout method
                    // Navigate to login page
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()), // Ensure this path is correct
                          (Route<dynamic> route) => false, // Remove all previous routes
                    );
                  },
                ),
                const Divider(),
                _buildSettingTile(
                  context,
                  title: 'Help & Support',
                  icon: Icons.help,
                  onTap: () {
                    // Navigate to help and support
                  },
                ),
                _buildSettingTile(
                  context,
                  title: 'About App',
                  icon: Icons.info,
                  onTap: () {
                    // Show app information
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, {required String title, required IconData icon, Color? color, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.blueAccent),
        title: Text(title, style: GoogleFonts.notoSerif(fontSize: 18)),
        onTap: onTap,
      ),
    );
  }
}