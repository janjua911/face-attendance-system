import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class EmbeddingService {
  static const String apiUrl =
      'https://janjua119-face-attendance-api.hf.space';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<double>?> _getEmbedding(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/get-embedding'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': imageUrl}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<double>.from(data['embedding']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  List<double> _averageEmbeddings(List<List<double>> embeddings) {
    int size = embeddings[0].length;
    List<double> avg = List.filled(size, 0.0);
    for (var emb in embeddings) {
      for (int i = 0; i < size; i++) {
        avg[i] += emb[i];
      }
    }
    for (int i = 0; i < size; i++) {
      avg[i] /= embeddings.length;
    }
    double norm = 0;
    for (var val in avg) norm += val * val;
    norm = _sqrt(norm);
    return avg.map((v) => v / norm).toList();
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double z = x / 2;
    for (int i = 0; i < 50; i++) {
      z = z - (z * z - x) / (2 * z);
    }
    return z;
  }

  Future<Map<String, dynamic>> generateAndSaveEmbedding({
    required String studentUid,
    required List<String> photoUrls,
    Function(String)? onProgress,
  }) async {
    try {
      if (photoUrls.isEmpty) {
        return {'success': false, 'message': 'No photos found'};
      }

      onProgress?.call('🧠 Generating face embeddings...');

      List<List<double>> validEmbeddings = [];
      int failed = 0;

      final urlsToProcess = photoUrls.take(10).toList();

      for (int i = 0; i < urlsToProcess.length; i++) {
        onProgress?.call(
            '📸 Processing photo ${i + 1}/${urlsToProcess.length}...');

        final embedding = await _getEmbedding(urlsToProcess[i]);

        if (embedding != null) {
          validEmbeddings.add(embedding);
        } else {
          failed++;
        }
      }

      if (validEmbeddings.isEmpty) {
        await _db.collection('students').doc(studentUid).update({
          'embeddingStatus': 'failed',
        });
        return {
          'success': false,
          'message': 'No valid face detected. Please re-upload clear face photos.'
        };
      }

      onProgress?.call('💾 Saving embedding...');
      final avgEmbedding = _averageEmbeddings(validEmbeddings);

      await _db.collection('students').doc(studentUid).update({
        'faceEmbedding': avgEmbedding,
        'embeddingModel': 'Facenet512',
        'embeddingStatus': 'complete',
        'embeddingUpdatedAt': Timestamp.now(),
        'validPhotos': validEmbeddings.length,
        'totalPhotos': urlsToProcess.length,
      });

      return {
        'success': true,
        'validPhotos': validEmbeddings.length,
        'totalPhotos': urlsToProcess.length,
        'failedPhotos': failed,
      };
    } catch (e) {
      await _db.collection('students').doc(studentUid).update({
        'embeddingStatus': 'failed',
      });
      return {'success': false, 'message': e.toString()};
    }
  }
}