import 'package:application_1/attendence.dart';
import 'package:application_1/ManageStudent.dart';
import 'package:application_1/viewstudent.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  final String userEmail;

  const HomeScreen({super.key, required this.userEmail});

  Future<void> markAttendance(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('attendance').add({
        'email': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toString(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance marked successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // 🔹 Reusable Button Card
  Widget buildMenuCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 35, color: Colors.white),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            fontFamily: 'new1',
            fontSize: 35,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 242, 187, 158),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),

      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),

        // 🌈 Gradient Background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // 👋 Welcome Text
            const Text(
              "Welcome 👋",
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(userEmail, style: const TextStyle(color: Colors.white70)),

            const SizedBox(height: 30),

            // 📦 Menu Cards
            buildMenuCard(
              context: context,
              title: "View Students",
              icon: Icons.visibility,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ViewStudentsScreen(),
                  ),
                );
              },
            ),

            buildMenuCard(
              context: context,
              title: "Mark Attendance",
              icon: Icons.check_circle,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceScreen(),
                  ),
                );
              },
            ),

            buildMenuCard(
              context: context,
              title: "Manage Students",
              icon: Icons.settings,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageStudent(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
