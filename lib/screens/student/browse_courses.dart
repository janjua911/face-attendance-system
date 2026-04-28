import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BrowseCoursesScreen extends StatefulWidget {
  const BrowseCoursesScreen({super.key});

  @override
  State<BrowseCoursesScreen> createState() => _BrowseCoursesScreenState();
}

class _BrowseCoursesScreenState extends State<BrowseCoursesScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  Set<String> _enrolledCourseIds = {};
  Set<String> _pendingCourseIds = {};

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('studentId', isEqualTo: uid)
        .get();

    Set<String> enrolled = {};
    Set<String> pending = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'approved') enrolled.add(data['courseId']);
      if (data['status'] == 'pending') pending.add(data['courseId']);
    }

    setState(() {
      _enrolledCourseIds = enrolled;
      _pendingCourseIds = pending;
    });
  }

  Future<void> _sendRequest(Map<String, dynamic> courseData) async {
    try {
      // Get student name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final studentName = userDoc['name'];

      final db = FirebaseFirestore.instance;
      final docRef = db.collection('enrollments').doc();

      await docRef.set({
        'enrollmentId': docRef.id,
        'studentId': uid,
        'studentName': studentName,
        'courseId': courseData['courseId'],
        'courseName': courseData['name'],
        'courseCode': courseData['code'],
        'status': 'pending',
        'requestedAt': Timestamp.now(),
      });

      setState(() => _pendingCourseIds.add(courseData['courseId']));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request bhej di! Admin approve karega ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Browse Courses'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.blue));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Koi course available nahi',
                  style: TextStyle(color: Colors.white38)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, i) {
              final data =
                  snapshot.data!.docs[i].data() as Map<String, dynamic>;
              final courseId = data['courseId'];
              final isEnrolled = _enrolledCourseIds.contains(courseId);
              final isPending = _pendingCourseIds.contains(courseId);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isEnrolled
                        ? Colors.green.withOpacity(0.4)
                        : isPending
                            ? Colors.yellow.withOpacity(0.4)
                            : Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.book,
                              color: Colors.blue, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text(
                                  '${data['code']} • ${data['creditHours']} CR',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('👨‍🏫 ${data['teacherName']}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                    Text('📚 ${data['department']}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 12),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isEnrolled || isPending
                            ? null
                            : () => _sendRequest(data),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEnrolled
                              ? Colors.green
                              : isPending
                                  ? Colors.yellow.shade700
                                  : Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          isEnrolled
                              ? '✅ Enrolled'
                              : isPending
                                  ? '⏳ Request Pending'
                                  : 'Send Enrollment Request',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}