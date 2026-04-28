import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyAttendanceScreen extends StatelessWidget {
  const MyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text('My Attendance'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('enrollments')
            .where('studentId', isEqualTo: uid)
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, enrollSnap) {
          if (enrollSnap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }

          if (!enrollSnap.hasData || enrollSnap.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Koi enrolled course nahi',
                      style: TextStyle(color: Colors.white38, fontSize: 16)),
                  Text('Pehle courses mein enroll karo',
                      style: TextStyle(color: Colors.white24, fontSize: 12)),
                ],
              ),
            );
          }

          final enrollments = enrollSnap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: enrollments.length,
            itemBuilder: (ctx, i) {
              final enrollment =
                  enrollments[i].data() as Map<String, dynamic>;
              final courseId = enrollment['courseId'];
              final courseName = enrollment['courseName'];
              final courseCode = enrollment['courseCode'];

              return _CourseAttendanceCard(
                uid: uid,
                courseId: courseId,
                courseName: courseName,
                courseCode: courseCode,
              );
            },
          );
        },
      ),
    );
  }
}

class _CourseAttendanceCard extends StatelessWidget {
  final String uid;
  final String courseId;
  final String courseName;
  final String courseCode;

  const _CourseAttendanceCard({
    required this.uid,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: uid)
          .where('courseId', isEqualTo: courseId)
          .snapshots(),
      builder: (context, attSnap) {
        int total = 0;
        int present = 0;
        int absent = 0;

        if (attSnap.hasData && attSnap.data!.docs.isNotEmpty) {
          total = attSnap.data!.docs.length;
          present = attSnap.data!.docs
              .where((d) =>
                  (d.data() as Map<String, dynamic>)['status'] ==
                  'present')
              .length;
          absent = total - present;
        }

        final percentage =
            total > 0 ? ((present / total) * 100).toStringAsFixed(1) : '0';
        final percentVal = total > 0 ? (present / total) * 100 : 0.0;
        final isLow = percentVal < 75 && total > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLow
                  ? Colors.red.withOpacity(0.5)
                  : Colors.green.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              // Course Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isLow
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.book,
                        color: isLow ? Colors.red : Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(courseName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(courseCode,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Percentage Circle
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLow
                            ? Colors.red.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        border: Border.all(
                          color: isLow ? Colors.red : Colors.green,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            color: isLow ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Row
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatBox('Total', total.toString(), Colors.blue),
                        _StatBox('Present', present.toString(), Colors.green),
                        _StatBox('Absent', absent.toString(), Colors.red),
                      ],
                    ),

                    // Progress Bar
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: total > 0 ? present / total : 0,
                        backgroundColor: Colors.red.withOpacity(0.3),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                                isLow ? Colors.red : Colors.green),
                        minHeight: 8,
                      ),
                    ),

                    // Low attendance warning
                    if (isLow) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning,
                                color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '⚠️ Low Attendance! 75% se upar rakho!',
                                style: TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}