import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class FaceRecognitionService {
  // Apna HuggingFace URL yahan likho
  static const String apiUrl =
      'https://janjua119-face-attendance-api.hf.space';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cosine similarity calculate karo
  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return dot / (sqrt(normA) * sqrt(normB));
  }

  double sqrt(double x) => x <= 0 ? 0 : _sqrtHelper(x);
  double _sqrtHelper(double x) {
    double z = x / 2;
    for (int i = 0; i < 50; i++) {
      z = z - (z * z - x) / (2 * z);
    }
    return z;
  }

  // Cloudinary URL se embedding get karo
  Future<List<double>?> getEmbeddingFromUrl(String imageUrl) async {
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

  // Cloudinary URL upload karke recognize karo
  Future<Map<String, dynamic>> recognizeFromUrl(
      String imageUrl) async {
    try {
      // Step 1: API se embedding lo
      final response = await http.post(
        Uri.parse('$apiUrl/get-embedding'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': imageUrl}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'API error'
        };
      }

      final apiData = jsonDecode(response.body);
      if (apiData['success'] != true) {
        return {'success': false, 'message': 'No face detected'};
      }

      List<double> testEmbedding =
          List<double>.from(apiData['embedding']);

      // Step 2: Firestore se sab embeddings fetch karo
      final students =
          await _db.collection('students').get();

      String? bestMatch;
      String? bestMatchId;
      double bestScore = -1;
      List<Map<String, dynamic>> allScores = [];

      for (var doc in students.docs) {
        final data = doc.data();
        final stored = data['faceEmbedding'];

        if (stored == null || (stored as List).isEmpty) continue;
        if (stored.length != 512) continue;

        List<double> storedEmbedding =
            List<double>.from(stored);

        double score =
            _cosineSimilarity(testEmbedding, storedEmbedding);

        allScores.add({
          'name': data['name'],
          'uid': data['uid'],
          'score': score,
        });

        if (score > bestScore) {
          bestScore = score;
          bestMatch = data['name'];
          bestMatchId = data['uid'];
        }
      }

      // Sort scores
      allScores.sort((a, b) =>
          (b['score'] as double).compareTo(a['score'] as double));

      // Threshold check — 0.55 strict enough
      if (bestScore >= 0.55) {
        return {
          'success': true,
          'identified': true,
          'name': bestMatch,
          'uid': bestMatchId,
          'confidence': bestScore,
          'allScores': allScores,
        };
      } else {
        return {
          'success': true,
          'identified': false,
          'message': 'Unknown person',
          'bestScore': bestScore,
          'allScores': allScores,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}