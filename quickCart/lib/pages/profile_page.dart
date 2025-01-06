import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
        ),
        body: const Center(
          child: Text(
            'No user logged in',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue], // Gradient colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error fetching data'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('User not found in Firestore'));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40), // Increased space above the title
                  Center(
                    child: Text(
                      'User Profile',
                      style: GoogleFonts.lobster(
                        fontSize: 60, // Adjust font size as needed
                        color: Colors.blueAccent, // Change color if needed
                      ),
                    ),
                  ), // Space between title and profile image
                  const SizedBox(height: 60),
                  _buildInfoCard('Name:', userData["name"] ?? "N/A"),
                  _buildInfoCard('Email:', userData["email"] ?? "N/A"),
                  _buildInfoCard('Citizen ID cards:', userData["cccd"] ?? "N/A"),
                  _buildInfoCard('Birth Date:', userData["dob"] ?? "N/A"),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSerif(fontSize: 18),
          ),
          const SizedBox(width: 8), // Reduce space between title and value
          Text(
            value,
            style: GoogleFonts.notoSerif(fontSize: 18),
            textAlign: TextAlign.center, // Center align the value
          ),
        ],
      ),
    );
  }
}