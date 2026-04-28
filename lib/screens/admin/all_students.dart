import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_student.dart';

class AllStudentsScreen extends StatelessWidget {
  const AllStudentsScreen({super.key});

  Future<void> _deleteStudent(
      BuildContext context, String uid, String name) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Delete Student?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '$name ko permanently delete karna chahte ho?\nYeh action undo nahi ho sakti!',
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = FirebaseFirestore.instance;

      // Firestore se delete
      await db.collection('students').doc(uid).delete();
      await db.collection('users').doc(uid).delete();

      // Enrollments bhi delete
      final enrollments = await db
          .collection('enrollments')
          .where('studentId', isEqualTo: uid)
          .get();
      for (var doc in enrollments.docs) {
        await doc.reference.delete();
      }

      // Attendance bhi delete
      final attendance = await db
          .collection('attendance')
          .where('studentId', isEqualTo: uid)
          .get();
      for (var doc in attendance.docs) {
        await doc.reference.delete();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Student deleted ✅'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text('All Students'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Koi student registered nahi',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 16)),
                ],
              ),
            );
          }

          final students = snapshot.data!.docs;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      'Total Students: ${students.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final data =
                        students[i].data() as Map<String, dynamic>;
                    final uid = data['uid'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                Colors.green.withOpacity(0.2),
                            backgroundImage: (data['photoUrls'] !=
                                        null &&
                                    (data['photoUrls'] as List)
                                        .isNotEmpty)
                                ? NetworkImage(data['photoUrls'][0])
                                : null,
                            child: (data['photoUrls'] == null ||
                                    (data['photoUrls'] as List)
                                        .isEmpty)
                                ? Text(
                                    data['name'][0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(data['name'],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                Text('Roll: ${data['rollNo']}',
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12)),
                                Text(data['department'],
                                    style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12)),
                                Text(data['email'],
                                    style: const TextStyle(
                                        color: Colors.white24,
                                        fontSize: 11)),
                              ],
                            ),
                          ),

                          // Action Buttons
                          Column(
                            children: [
                              // Edit
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditStudentScreen(
                                      uid: uid,
                                      data: data,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue, size: 20),
                                tooltip: 'Edit',
                              ),
                              // Delete
                              IconButton(
                                onPressed: () => _deleteStudent(
                                    context, uid, data['name']),
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}