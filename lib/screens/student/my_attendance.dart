import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF3F3D9E);
  static const Color accentCyan = Color(0xFF00B4D8);
  static const Color accentLight = Color(0xFF90E0EF);
  
  static const Color backgroundDark = Color(0xFF0F0F1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252542);
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textHint = Color(0xFF6B6B8D);
  
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryDark],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceDark, Color(0xFF1E1E35)],
  );
  
  static List<BoxShadow> get defaultShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

class MyAttendanceScreen extends StatelessWidget {
  const MyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildGradientAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('enrollments')
            .where('studentId', isEqualTo: uid)
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, enrollSnap) {
          if (enrollSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
              ),
            );
          }

          if (!enrollSnap.hasData || enrollSnap.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final enrollments = enrollSnap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: enrollments.length,
            itemBuilder: (ctx, i) {
              final enrollment = enrollments[i].data() as Map<String, dynamic>;
              final courseId = enrollment['courseId'];
              final courseName = enrollment['courseName'];
              final courseCode = enrollment['courseCode'];

              return CourseAttendanceCard(
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

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      title: const Text(
        'My Attendance',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppTheme.textPrimary,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart,
              size: 64,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Enrolled Courses',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse and enroll in courses first',
            style: TextStyle(color: AppTheme.textHint, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class CourseAttendanceCard extends StatelessWidget {
  final String uid;
  final String courseId;
  final String courseName;
  final String courseCode;

  const CourseAttendanceCard({
    super.key,
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

        if (attSnap.hasData && attSnap.data!.docs.isNotEmpty) {
          total = attSnap.data!.docs.length;
          present = attSnap.data!.docs
              .where((d) => (d.data() as Map<String, dynamic>)['status'] == 'present')
              .length;
        }
        
        final absent = total - present;
        final percentage = total > 0 ? ((present / total) * 100).toStringAsFixed(1) : '0';
        final percentVal = total > 0 ? (present / total) * 100 : 0.0;
        final isLow = percentVal < 75 && total > 0;
        final attendanceColor = isLow ? AppTheme.error : AppTheme.success;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: attendanceColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      attendanceColor.withOpacity(0.15),
                      attendanceColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [attendanceColor, attendanceColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.menu_book, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              courseCode,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Percentage Circle
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: attendanceColor.withOpacity(0.15),
                        border: Border.all(
                          color: attendanceColor,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                color: attendanceColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (total > 0)
                              Text(
                                'of $total',
                                style: TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 8,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatBox(
                          label: 'Total Classes',
                          value: total.toString(),
                          color: AppTheme.info,
                          icon: Icons.calendar_today,
                        ),
                        _StatBox(
                          label: 'Present',
                          value: present.toString(),
                          color: AppTheme.success,
                          icon: Icons.check_circle,
                        ),
                        _StatBox(
                          label: 'Absent',
                          value: absent.toString(),
                          color: AppTheme.error,
                          icon: Icons.cancel,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Progress Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Attendance Rate',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                color: attendanceColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: total > 0 ? present / total : 0,
                            backgroundColor: AppTheme.error.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isLow ? AppTheme.error : AppTheme.success,
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),

                    // Low attendance warning
                    if (isLow && total > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.warning_rounded,
                                color: AppTheme.error,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Low Attendance Warning! Maintain at least 75% to be eligible for exams.',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Good attendance message
                    if (!isLow && total > 0 && percentVal >= 75) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.thumb_up_rounded,
                                color: AppTheme.success,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Good Attendance! Keep it up!',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 12,
                                ),
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
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
          ),
        ],
      ),
    );
  }
}