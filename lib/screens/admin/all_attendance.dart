import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllAttendanceScreen extends StatefulWidget {
  const AllAttendanceScreen({super.key});

  @override
  State<AllAttendanceScreen> createState() => _AllAttendanceScreenState();
}

class _AllAttendanceScreenState extends State<AllAttendanceScreen> {
  String _filterStatus = 'all'; // all / present / absent

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('Attendance Records'),
      ),
      body: Column(
        children: [
          // Filter Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _filterStatus == 'all',
                  color: Colors.blue,
                  onTap: () => setState(() => _filterStatus = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Present ✅',
                  isSelected: _filterStatus == 'present',
                  color: Colors.green,
                  onTap: () =>
                      setState(() => _filterStatus = 'present'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Absent ❌',
                  isSelected: _filterStatus == 'absent',
                  color: Colors.red,
                  onTap: () =>
                      setState(() => _filterStatus = 'absent'),
                ),
              ],
            ),
          ),

          // Records List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filterStatus == 'all'
                  ? FirebaseFirestore.instance
                      .collection('attendance')
                      .orderBy('markedAt', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('attendance')
                      .where('status', isEqualTo: _filterStatus)
                      .orderBy('markedAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.red));
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text('Koi attendance record nahi',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 16)),
                      ],
                    ),
                  );
                }

                final records = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final data =
                        records[i].data() as Map<String, dynamic>;
                    final isPresent = data['status'] == 'present';
                    final markedAt =
                        (data['markedAt'] as Timestamp).toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPresent
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Status icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPresent
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isPresent
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: isPresent
                                  ? Colors.green
                                  : Colors.red,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['studentName'] ?? 'Unknown',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Course ID: ${data['courseId']}',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11),
                                ),
                                Text(
                                  '${markedAt.day}/${markedAt.month}/${markedAt.year} — ${markedAt.hour}:${markedAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      color: Colors.white24,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),

                          // Method badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: data['method'] == 'face'
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              data['method'] == 'face'
                                  ? '🤖 Face'
                                  : '✋ Manual',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 10),
                            ),
                          ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.25) : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white38,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}