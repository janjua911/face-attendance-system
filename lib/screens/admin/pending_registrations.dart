import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingRegistrationsScreen extends StatelessWidget {
  const PendingRegistrationsScreen({super.key});

  Future<void> _updateStatus(
      BuildContext context, String enrollmentId, String status) async {
    await FirebaseFirestore.instance
        .collection('enrollments')
        .doc(enrollmentId)
        .update({'status': status});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved'
              ? 'Request Approved ✅'
              : 'Request Rejected ❌'),
          backgroundColor:
              status == 'approved' ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: const Text('Pending Registrations'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('enrollments')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.purple));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_reg,
                      size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Koi pending request nahi!',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 16)),
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
              final enrollmentId = snapshot.data!.docs[i].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              Colors.purple.withOpacity(0.2),
                          child: Text(
                            data['studentName'][0].toUpperCase(),
                            style:
                                const TextStyle(color: Colors.purple),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(data['studentName'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  'Course: ${data['courseName']} (${data['courseCode']})',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus(
                                context, enrollmentId, 'approved'),
                            icon: const Icon(Icons.check,
                                color: Colors.white, size: 16),
                            label: const Text('Approve',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus(
                                context, enrollmentId, 'rejected'),
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                            label: const Text('Reject',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                          ),
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