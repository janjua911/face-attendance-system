import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_session.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseId;
  final String courseName;
  final String courseCode;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Text(courseName),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceSessionScreen(
              courseId: courseId,
              courseName: courseName,
            ),
          ),
        ),
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text('Start Attendance',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.teal.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.book, color: Colors.teal, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(courseName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(courseCode,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Enrolled Students',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),

          // Students List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('enrollments')
                  .where('courseId', isEqualTo: courseId)
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.teal));
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            color: Colors.white24, size: 48),
                        SizedBox(height: 8),
                        Text('Koi enrolled student nahi',
                            style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                final students = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final data =
                        students[i].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Colors.teal.withOpacity(0.2),
                            child: Text(
                              data['studentName'][0].toUpperCase(),
                              style:
                                  const TextStyle(color: Colors.teal),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(data['studentName'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}