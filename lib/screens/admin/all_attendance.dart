import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// AppTheme for consistent styling
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

class AllAttendanceScreen extends StatefulWidget {
  const AllAttendanceScreen({super.key});

  @override
  State<AllAttendanceScreen> createState() => _AllAttendanceScreenState();
}

class _AllAttendanceScreenState extends State<AllAttendanceScreen> {
  String _filterStatus = 'all'; // all / present / absent
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildGradientAppBar(),
      body: Column(
        children: [
          // Stats Summary
          _buildStatsSummary(),
          
          // Search Bar
          _buildSearchBar(),
          
          // Filter Buttons
          _buildFilterChips(),
          
          // Records List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getAttendanceStream(),
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

                var records = snapshot.data!.docs;
                
                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  records = records.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final studentName = data['studentName']?.toString().toLowerCase() ?? '';
                    final courseId = data['courseId']?.toString().toLowerCase() ?? '';
                    return studentName.contains(_searchQuery.toLowerCase()) ||
                           courseId.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (records.isEmpty) {
                  return _buildNoResultsState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final data = records[i].data() as Map<String, dynamic>;
                    return _buildAttendanceCard(data, records[i].id);
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
        'Attendance Records',
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

  Widget _buildStatsSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 80);
        }
        
        final records = snapshot.data!.docs;
        final total = records.length;
        final present = records.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'present';
        }).length;
        final absent = total - present;
        final attendanceRate = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0';
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.defaultShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.people_outline, 'Total', total.toString(), AppTheme.primaryPurple),
              Container(width: 1, height: 40, color: AppTheme.surfaceLight),
              _buildStatItem(Icons.check_circle_outline, 'Present', present.toString(), AppTheme.success),
              Container(width: 1, height: 40, color: AppTheme.surfaceLight),
              _buildStatItem(Icons.cancel_outlined, 'Absent', absent.toString(), AppTheme.error),
              Container(width: 1, height: 40, color: AppTheme.surfaceLight),
              _buildStatItem(Icons.trending_up, 'Rate', '$attendanceRate%', AppTheme.accentCyan),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textHint,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            hintText: 'Search by student name or course ID...',
            hintStyle: const TextStyle(color: AppTheme.textHint),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryPurple),
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

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'All Records',
            icon: Icons.list_alt,
            isSelected: _filterStatus == 'all',
            color: AppTheme.primaryPurple,
            onTap: () => setState(() => _filterStatus = 'all'),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Present',
            icon: Icons.check_circle,
            isSelected: _filterStatus == 'present',
            color: AppTheme.success,
            onTap: () => setState(() => _filterStatus = 'present'),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Absent',
            icon: Icons.cancel,
            isSelected: _filterStatus == 'absent',
            color: AppTheme.error,
            onTap: () => setState(() => _filterStatus = 'absent'),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getAttendanceStream() {
    var query = FirebaseFirestore.instance
        .collection('attendance')
        .orderBy('markedAt', descending: true);
    
    if (_filterStatus == 'present') {
      query = query.where('status', isEqualTo: 'present');
    } else if (_filterStatus == 'absent') {
      query = query.where('status', isEqualTo: 'absent');
    }
    
    return query.snapshots();
  }

  Widget _buildAttendanceCard(Map<String, dynamic> data, String docId) {
    final isPresent = data['status'] == 'present';
    final markedAt = (data['markedAt'] as Timestamp).toDate();
    final method = data['method'] ?? 'manual';
    final courseName = data['courseName'] ?? data['courseId'] ?? 'Unknown Course';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent ? AppTheme.success.withOpacity(0.3) : AppTheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAttendanceDetails(data, markedAt),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status icon with animated container
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: isPresent
                            ? const LinearGradient(
                                colors: [AppTheme.success, Color(0xFF66BB6A)],
                              )
                            : const LinearGradient(
                                colors: [AppTheme.error, Color(0xFFEF5350)],
                              ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isPresent ? AppTheme.success : AppTheme.error).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPresent ? Icons.check_rounded : Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Student Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['studentName'] ?? 'Unknown Student',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
                                  courseName.length > 25 ? '${courseName.substring(0, 25)}...' : courseName,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: method == 'face'
                                      ? AppTheme.primaryPurple.withOpacity(0.2)
                                      : AppTheme.warning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      method == 'face' ? Icons.face_rounded : Icons.edit_note_rounded,
                                      size: 10,
                                      color: method == 'face' ? AppTheme.primaryPurple : AppTheme.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      method == 'face' ? 'Face Auth' : 'Manual',
                                      style: TextStyle(
                                        color: method == 'face' ? AppTheme.primaryPurple : AppTheme.warning,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(markedAt),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(markedAt),
                          style: const TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Progress indicator for attendance analytics
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isPresent ? MediaQuery.of(context).size.width * 0.6 : 0,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: isPresent
                              ? const LinearGradient(
                                  colors: [AppTheme.success, Color(0xFF81C784)],
                                )
                              : const LinearGradient(
                                  colors: [AppTheme.error, Color(0xFFEF9A9A)],
                                ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
              Icons.assignment_turned_in_outlined,
              size: 64,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Attendance Records',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Attendance records will appear here',
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
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'No matching records found',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(color: AppTheme.textHint, fontSize: 13),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
            icon: const Icon(Icons.clear_rounded),
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

  void _showAttendanceDetails(Map<String, dynamic> data, DateTime markedAt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (data['status'] == 'present' ? AppTheme.success : AppTheme.error).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    data['status'] == 'present' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: data['status'] == 'present' ? AppTheme.success : AppTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['studentName'] ?? 'Unknown Student',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        data['status'] == 'present' ? 'Present' : 'Absent',
                        style: TextStyle(
                          color: data['status'] == 'present' ? AppTheme.success : AppTheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.surfaceLight),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.school_outlined, 'Course', data['courseName'] ?? data['courseId'] ?? 'N/A'),
            _buildDetailRow(Icons.numbers_outlined, 'Course ID', data['courseId'] ?? 'N/A'),
            _buildDetailRow(Icons.calendar_today_rounded, 'Date', _formatDate(markedAt)),
            _buildDetailRow(Icons.access_time_rounded, 'Time', _formatTime(markedAt)),
            _buildDetailRow(
              Icons.qr_code_scanner_rounded,
              'Method',
              data['method'] == 'face' ? 'Face Recognition' : 'Manual Entry',
              iconColor: data['method'] == 'face' ? AppTheme.primaryPurple : AppTheme.warning,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppTheme.primaryPurple),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textHint, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.25), color.withOpacity(0.15)],
                )
              : null,
          color: isSelected ? null : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : AppTheme.textHint.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppTheme.textHint,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textHint,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}