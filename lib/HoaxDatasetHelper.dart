import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class HoaxDatasetHelper {
  static List<Map<String, dynamic>> _dataset = [];
  static bool _isLoaded = false;

  // Load CSV dari assets
  static Future<void> loadDataset() async {
    if (_isLoaded) return;

    try {
      final rawData = await rootBundle.loadString('assets/data/hoax_dataset.csv');
      List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);

      if (listData.isEmpty) return;

      // Ambil header (baris pertama)
      List<String> headers = listData[0].map((e) => e.toString()).toList();

      // Konversi ke List of Maps
      _dataset = listData.skip(1).map((row) {
        Map<String, dynamic> item = {};
        for (int i = 0; i < headers.length; i++) {
          item[headers[i]] = row[i].toString();
        }
        return item;
      }).toList();

      _isLoaded = true;
      print("✅ Dataset loaded: ${_dataset.length} records");
    } catch (e) {
      print("❌ Error loading dataset: $e");
    }
  }

  // Cari kecocokan berdasarkan kata kunci
  static List<Map<String, dynamic>> searchByKeywords(String query) {
    if (!_isLoaded) return [];

    query = query.toLowerCase();
    
    return _dataset.where((item) {
      final judul = item['judul']?.toString().toLowerCase() ?? '';
      final konten = item['konten']?.toString().toLowerCase() ?? '';
      
      return judul.contains(query) || konten.contains(query);
    }).toList();
  }

  // Cari kecocokan dengan similarity (sederhana)
  static Map<String, dynamic>? findSimilarNews(String text) {
    if (!_isLoaded || text.isEmpty) return null;

    text = text.toLowerCase();
    double maxSimilarity = 0.0;
    Map<String, dynamic>? bestMatch;

    for (var item in _dataset) {
      final konten = item['konten']?.toString().toLowerCase() ?? '';
      final similarity = _calculateSimilarity(text, konten);

      if (similarity > maxSimilarity && similarity > 0.3) { // threshold 30%
        maxSimilarity = similarity;
        bestMatch = item;
      }
    }

    return bestMatch;
  }

  // Hitung similarity sederhana (Jaccard)
  static double _calculateSimilarity(String text1, String text2) {
    Set<String> words1 = text1.split(RegExp(r'\s+')).toSet();
    Set<String> words2 = text2.split(RegExp(r'\s+')).toSet();

    int intersection = words1.intersection(words2).length;
    int union = words1.union(words2).length;

    return union > 0 ? intersection / union : 0.0;
  }

  // Format hasil pencarian untuk ditampilkan
  static String formatSearchResult(Map<String, dynamic> data) {
    return """
🔍 **DITEMUKAN DI DATABASE LOKAL**

📰 **Judul:** ${data['judul']}
📝 **Kategori:** ${data['kategori']}
⚠️ **Status:** ${data['status']}
✅ **Sumber Verifikasi:** ${data['sumber_verifikasi']}

📋 **Ringkasan:**
${data['konten']}
""";
  }

  // Get all data
  static List<Map<String, dynamic>> getAllData() => _dataset;
  
  // Check if dataset is loaded
  static bool isLoaded() => _isLoaded;
}