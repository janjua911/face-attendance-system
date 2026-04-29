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

class BrowseCoursesScreen extends StatefulWidget {
  const BrowseCoursesScreen({super.key});

  @override
  State<BrowseCoursesScreen> createState() => _BrowseCoursesScreenState();
}

class _BrowseCoursesScreenState extends State<BrowseCoursesScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  Set<String> _enrolledCourseIds = {};
  Set<String> _pendingCourseIds = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _showSnackBar('Enrollment request sent! Admin will approve.', AppTheme.success);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', AppTheme.error);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.success ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildGradientAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                var courses = snapshot.data!.docs;
                
                if (_searchQuery.isNotEmpty) {
                  courses = courses.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name']?.toString().toLowerCase() ?? '';
                    final code = data['code']?.toString().toLowerCase() ?? '';
                    return name.contains(_searchQuery.toLowerCase()) ||
                           code.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (courses.isEmpty) {
                  return _buildNoResultsState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: courses.length,
                  itemBuilder: (ctx, i) {
                    final data = courses[i].data() as Map<String, dynamic>;
                    final courseId = data['courseId'];
                    final isEnrolled = _enrolledCourseIds.contains(courseId);
                    final isPending = _pendingCourseIds.contains(courseId);
                    return _buildCourseCard(data, isEnrolled, isPending);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      title: const Text(
        'Browse Courses',
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppTheme.textPrimary),
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search by course name or code...',
            hintStyle: const TextStyle(color: AppTheme.textHint),
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryPurple),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textHint),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> data, bool isEnrolled, bool isPending) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (isEnrolled) {
      statusColor = AppTheme.success;
      statusText = 'Enrolled';
      statusIcon = Icons.check_circle;
    } else if (isPending) {
      statusColor = AppTheme.warning;
      statusText = 'Pending';
      statusIcon = Icons.hourglass_empty;
    } else {
      statusColor = AppTheme.info;
      statusText = 'Available';
      statusIcon = Icons.radio_button_unchecked;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.accentCyan],
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['name'] ?? 'Unknown Course',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 12, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                data['code'] ?? 'CODE',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${data['creditHours'] ?? 3} CR',
                                style: const TextStyle(
                                  color: AppTheme.warning,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data['teacherName'] ?? 'Not Assigned',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.school, size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data['department'] ?? 'General',
                      style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isEnrolled || isPending ? null : () => _sendRequest(data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnrolled
                        ? AppTheme.success
                        : isPending
                            ? AppTheme.warning
                            : AppTheme.primaryPurple,
                    foregroundColor: AppTheme.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEnrolled ? Icons.check_circle : 
                        isPending ? Icons.hourglass_empty : 
                        Icons.send,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEnrolled ? 'Enrolled' : 
                        isPending ? 'Request Pending' : 
                        'Send Enrollment Request',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
              Icons.menu_book,
              size: 64,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Courses Available',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for new courses',
            style: TextStyle(color: AppTheme.textHint, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
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
              Icons.search_off,
              size: 64,
              color: AppTheme.textHint,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Matching Courses',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No courses match "$_searchQuery"',
            style: const TextStyle(color: AppTheme.textHint, fontSize: 14),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Search'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryPurple,
              side: const BorderSide(color: AppTheme.primaryPurple),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}