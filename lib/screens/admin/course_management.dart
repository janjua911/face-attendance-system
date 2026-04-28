import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_course.dart';

class CourseManagementScreen extends StatelessWidget {
  const CourseManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text('Course Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateCourseScreen())),
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('New Course', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Koi course nahi hai',
                      style: TextStyle(color: Colors.white38, fontSize: 16)),
                  Text('+ button se course banao',
                      style: TextStyle(color: Colors.white24)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, i) {
              final data =
                  snapshot.data!.docs[i].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.book,
                          color: Colors.orange, size: 28),
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
                          const SizedBox(height: 4),
                          Text(
                            '${data['code']} • ${data['department']}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                          Text(
                            'Teacher: ${data['teacherName']}',
                            style: const TextStyle(
                                color: Colors.orange, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${data['creditHours']} CR',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(data['semester'],
                            style: const TextStyle(
                                color: Colors.white24, fontSize: 10)),
                      ],
                    )
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