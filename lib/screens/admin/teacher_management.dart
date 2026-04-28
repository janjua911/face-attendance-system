import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_teacher.dart';
import 'edit_teacher.dart';

class TeacherManagementScreen extends StatelessWidget {
  const TeacherManagementScreen({super.key});

  Future<void> _deleteTeacher(
      BuildContext context, String uid, String name) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Delete Teacher?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '$name ko delete karna chahte ho?',
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = FirebaseFirestore.instance;
      await db.collection('teachers').doc(uid).delete();
      await db.collection('users').doc(uid).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Teacher deleted ✅'),
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
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('Teacher Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddTeacherScreen())),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Teacher',
            style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teachers')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: Colors.teal));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline,
                      size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Koi teacher registered nahi',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 16)),
                ],
              ),
            );
          }

          final teachers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            itemBuilder: (ctx, i) {
              final data =
                  teachers[i].data() as Map<String, dynamic>;
              final uid = data['uid'];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.teal.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          Colors.teal.withOpacity(0.2),
                      child: Text(
                        data['name'][0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(data['name'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text('ID: ${data['employeeId']}',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12)),
                          Text(data['department'],
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12)),
                          Text(
                            '${(data['assignedCourses'] as List?)?.length ?? 0} courses assigned',
                            style: const TextStyle(
                                color: Colors.teal,
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditTeacherScreen(
                                uid: uid,
                                data: data,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.edit,
                              color: Colors.blue, size: 20),
                        ),
                        IconButton(
                          onPressed: () => _deleteTeacher(
                              context, uid, data['name']),
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 20),
                        ),
                      ],
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