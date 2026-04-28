import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'browse_courses.dart';
import 'my_attendance.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text('Student Portal',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(),
        builder: (context, snapshot) {
          String studentName = 'Student';
          if (snapshot.hasData && snapshot.data!.exists) {
            studentName = snapshot.data!['name'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome, $studentName 🎓',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const Text('View your courses & attendance',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                const Text('Quick Actions',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.search,
                        title: 'Browse Courses',
                        subtitle: 'Find & enroll',
                        color: Colors.blue,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BrowseCoursesScreen())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.bar_chart,
                        title: 'My Attendance',
                        subtitle: 'View records',
                        color: Colors.green,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MyAttendanceScreen())),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // My Enrolled Courses
                const Text('My Courses',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('enrollments')
                      .where('studentId', isEqualTo: uid)
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.orange));
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.book_outlined,
                                  color: Colors.white24, size: 48),
                              SizedBox(height: 8),
                              Text('Koi enrolled course nahi',
                                  style:
                                      TextStyle(color: Colors.white38)),
                              Text('Browse Courses se enroll karo',
                                  style:
                                      TextStyle(color: Colors.white24,
                                          fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16213E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.orange.withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.book,
                                    color: Colors.orange),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(data['courseName'],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.bold)),
                                    Text(data['courseCode'],
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.green.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Text('Enrolled',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 11)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                // Pending Requests
                const SizedBox(height: 16),
                const Text('Pending Requests',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('enrollments')
                      .where('studentId', isEqualTo: uid)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Koi pending request nahi',
                              style: TextStyle(color: Colors.white38)),
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16213E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    Colors.yellow.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.pending,
                                  color: Colors.yellow),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(data['courseName'],
                                    style: const TextStyle(
                                        color: Colors.white)),
                              ),
                              const Text('Pending',
                                  style: TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}