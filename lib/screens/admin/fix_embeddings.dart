import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/embedding_service.dart';

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
  
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
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

// ONLY the FixEmbeddingsScreen class - NO PendingRegistrationsScreen here!
class FixEmbeddingsScreen extends StatefulWidget {
  const FixEmbeddingsScreen({super.key});

  @override
  State<FixEmbeddingsScreen> createState() => _FixEmbeddingsScreenState();
}

class _FixEmbeddingsScreenState extends State<FixEmbeddingsScreen> {
  bool _isProcessing = false;
  String _currentStatus = '';
  List<Map<String, dynamic>> _studentStatuses = [];
  bool _loaded = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final EmbeddingService _embeddingService = EmbeddingService();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('students')
        .get();

    List<Map<String, dynamic>> statuses = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final embedding = data['faceEmbedding'] as List? ?? [];
      final status = data['embeddingStatus'] ?? 'unknown';
      statuses.add({
        'uid': data['uid'],
        'name': data['name'],
        'photoUrls': data['photoUrls'] ?? [],
        'embeddingStatus': status,
        'embeddingSize': embedding.length,
        'validPhotos': data['validPhotos'] ?? 0,
      });
    }

    setState(() {
      _studentStatuses = statuses;
      _loaded = true;
    });
  }

  Future<void> _fixSingleStudent(Map<String, dynamic> student) async {
    final photoUrls = List<String>.from(student['photoUrls']);

    if (photoUrls.isEmpty) {
      _showSnack('${student['name']} has no photos!', AppTheme.error);
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStatus = 'Processing ${student['name']}...';
    });

    final result = await _embeddingService.generateAndSaveEmbedding(
      studentUid: student['uid'],
      photoUrls: photoUrls,
      onProgress: (msg) => setState(() => _currentStatus = msg),
    );

    setState(() => _isProcessing = false);

    if (result['success']) {
      _showSnack(
        '${student['name']} — Done! ${result['validPhotos']}/${result['totalPhotos']} photos used',
        AppTheme.success,
      );
    } else {
      _showSnack(
        '${student['name']} — Failed: ${result['message']}',
        AppTheme.error,
      );
    }

    await _loadStudents();
  }

  Future<void> _fixAllPending() async {
    final pending = _studentStatuses
        .where((s) => s['embeddingStatus'] != 'complete' || s['embeddingSize'] != 512)
        .toList();

    if (pending.isEmpty) {
      _showSnack('All students already have complete embeddings!', AppTheme.success);
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStatus = 'Starting batch processing...';
    });

    int success = 0;
    int failed = 0;

    for (var student in pending) {
      final photoUrls = List<String>.from(student['photoUrls']);
      if (photoUrls.isEmpty) {
        failed++;
        continue;
      }

      setState(() => _currentStatus = 'Processing: ${student['name']}');

      final result = await _embeddingService.generateAndSaveEmbedding(
        studentUid: student['uid'],
        photoUrls: photoUrls,
        onProgress: (msg) => setState(() => _currentStatus = msg),
      );

      if (result['success']) {
        success++;
      } else {
        failed++;
      }
    }

    setState(() {
      _isProcessing = false;
      _currentStatus = 'Completed! Success: $success, Failed: $failed';
    });

    _showSnack('Complete! $success successful, $failed failed', AppTheme.success);
    await _loadStudents();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.success ? Icons.check_circle : 
              color == AppTheme.error ? Icons.error : 
              Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
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
          if (_isProcessing) _buildProcessingCard(),
          if (!_isProcessing && _loaded) _buildActionButtons(),
          if (_loaded) _buildSearchBar(),
          Expanded(
            child: !_loaded
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                    ),
                  )
                : _buildStudentList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      title: const Text(
        'Fix Embeddings',
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

  Widget _buildProcessingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _currentStatus,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final pendingCount = _studentStatuses
        .where((s) => s['embeddingStatus'] != 'complete' || s['embeddingSize'] != 512)
        .length;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pending_actions, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Embeddings',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$pendingCount students need embedding',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: pendingCount == 0 ? null : _fixAllPending,
              icon: const Icon(Icons.auto_fix_high, color: Colors.white),
              label: Text(
                'Fix All Pending ($pendingCount)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: pendingCount == 0 ? Colors.grey : const Color(0xFF9C27B0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
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
            hintText: 'Search by student name...',
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

  Widget _buildStudentList() {
    final filteredStudents = _studentStatuses.where((student) {
      return student['name'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredStudents.isEmpty) {
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
              'No students found',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty ? 'No students available' : 'Try a different search term',
              style: const TextStyle(color: AppTheme.textHint, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStudents.length,
      itemBuilder: (ctx, i) {
        final student = filteredStudents[i];
        final status = student['embeddingStatus'];
        final size = student['embeddingSize'];
        final isComplete = status == 'complete' && size == 512;
        final photoCount = (student['photoUrls'] as List).length;

        Color statusColor = isComplete ? AppTheme.success : 
                           status == 'failed' ? AppTheme.error : 
                           AppTheme.warning;
        
        IconData statusIcon = isComplete ? Icons.check_circle :
                             status == 'failed' ? Icons.error :
                             Icons.hourglass_empty;
        
        String statusText = isComplete ? 'Complete (${student['validPhotos']} photos)' :
                            status == 'failed' ? 'Failed' :
                            'Pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'],
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$photoCount photos available',
                          style: const TextStyle(color: AppTheme.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  
                  if (!isComplete && !_isProcessing)
                    ElevatedButton(
                      onPressed: () => _fixSingleStudent(student),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Fix',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      ),
                    ),
                  if (isComplete)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_circle, color: AppTheme.success, size: 28),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}