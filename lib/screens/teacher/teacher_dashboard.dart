import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'course_detail.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('Teacher Portal',
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
            .collection('teachers')
            .doc(uid)
            .get(),
        builder: (context, teacherSnap) {
          if (!teacherSnap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          }

          final teacherData =
              teacherSnap.data!.data() as Map<String, dynamic>;
          final teacherName = teacherData['name'];
          final List assignedCourses =
              teacherData['assignedCourses'] ?? [];

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
                      colors: [Colors.teal, Colors.tealAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                          Text('Welcome, $teacherName 👨‍🏫',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              '${assignedCourses.length} course(s) assigned',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // My Courses
                const Text('My Courses',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (assignedCourses.isEmpty)
                  Container(
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
                          Text('Koi course assign nahi',
                              style: TextStyle(color: Colors.white38)),
                          Text('Admin se course assign karwao',
                              style: TextStyle(
                                  color: Colors.white24, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                else
                  ...assignedCourses.map((courseId) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('courses')
                          .doc(courseId)
                          .get(),
                      builder: (context, courseSnap) {
                        if (!courseSnap.hasData) {
                          return const SizedBox();
                        }
                        final course = courseSnap.data!.data()
                            as Map<String, dynamic>;

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseDetailScreen(
                                courseId: courseId,
                                courseName: course['name'],
                                courseCode: course['code'],
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.teal.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.book,
                                      color: Colors.teal, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(course['name'],
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Text(
                                          '${course['code']} • ${course['department']}',
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12)),
                                      Text(
                                          '${course['creditHours']} Credit Hours • ${course['semester']}',
                                          style: const TextStyle(
                                              color: Colors.white24,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    color: Colors.teal, size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}