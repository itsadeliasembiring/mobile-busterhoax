import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TanyaBerita extends StatefulWidget {
  const TanyaBerita({super.key});

  @override
  _TanyaBeritaState createState() => _TanyaBeritaState();
}

class _TanyaBeritaState extends State<TanyaBerita> {
  // --- KONFIGURASI API ---
  // Ganti dengan API Key valid Anda
  final String _geminiApiKey = "AIzaSyCtr3Vk7WYIWCHayRcQC-Xzxd0l8IrW-to"; 
  final String _factCheckApiKey = "AIzaSyCtr3Vk7WYIWCHayRcQC-Xzxd0l8IrW-to"; 

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Uint8List? _imageBytes;

  // --- FUNGSI FACT CHECK (Google Fact Check Tools API) ---
  Future<String> _checkFactWithGoogle(String query) async {
    try {
      final url = Uri.parse(
        'https://factchecktools.googleapis.com/v1alpha1/claims:search?query=${Uri.encodeComponent(query)}&key=$_factCheckApiKey&languageCode=id'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['claims'] != null && data['claims'].isNotEmpty) {
          StringBuffer result = StringBuffer();
          result.writeln("📋 **Hasil Fact-Check dari Google:**\n");
          
          int count = 0;
          for (var claim in data['claims']) {
            if (count >= 3) break; // Batasi 3 hasil teratas
            
            final text = claim['text'] ?? 'N/A';
            final claimant = claim['claimant'] ?? 'Unknown';
            
            if (claim['claimReview'] != null && claim['claimReview'].isNotEmpty) {
              final review = claim['claimReview'][0];
              final publisher = review['publisher']?['name'] ?? 'Unknown';
              final rating = review['textualRating'] ?? 'N/A';
              final title = review['title'] ?? '';
              final url = review['url'] ?? '';
              
              result.writeln("${count + 1}. **Klaim:** $text");
              result.writeln("   **Diklaim oleh:** $claimant");
              result.writeln("   **Rating:** $rating");
              result.writeln("   **Sumber:** $publisher");
              if (title.isNotEmpty) result.writeln("   **Detail:** $title");
              if (url.isNotEmpty) result.writeln("   **Link:** $url");
              result.writeln();
              
              count++;
            }
          }
          
          return result.toString();
        } else {
          return "ℹ️ Tidak ditemukan fact-check untuk klaim ini di database Google Fact Check Tools.";
        }
      } else {
        return "⚠️ Gagal mengakses Google Fact Check API (Status: ${response.statusCode})";
      }
    } catch (e) {
      return "❌ Error saat melakukan fact-check: $e";
    }
  }

  // --- FUNGSI IMAGE PICKER ---
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = File(image.path);
          _imageBytes = bytes;
        });
        _showImageAnalysisDialog();
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih gambar: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = File(image.path);
          _imageBytes = bytes;
        });
        _showImageAnalysisDialog();
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil foto: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pilih Sumber Gambar",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF76BC6B),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF76BC6B)),
                title: Text(
                  "Galeri",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF76BC6B)),
                title: Text(
                  "Kamera",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImageAnalysisDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Analisis Gambar Berita",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF76BC6B),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                "Gambar berhasil dipilih! Klik 'Analisis' untuk memeriksa keaslian berita.",
                style: GoogleFonts.poppins(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _imageBytes = null;
                });
                Navigator.pop(context);
              },
              child: Text(
                "Batal",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _analyzeImage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF76BC6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Analisis",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- LOGIKA ANALISIS GAMBAR (GEMINI) ---
  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _geminiApiKey,
      );

      final prompt = '''
Anda adalah BusterHoax Bot, ahli dalam menganalisis keaslian berita dan mendeteksi hoax.
Analisis gambar berita ini dengan detail dan berikan:

1. **Status**: Apakah ini berita HOAX, BENAR, atau TIDAK DAPAT DIVERIFIKASI
2. **Ringkasan Berita**: Jelaskan isi berita dalam gambar ini
3. **Alasan Detail**: Jelaskan mengapa Anda memberikan kesimpulan tersebut
4. **Tanda-tanda yang Ditemukan**: List indikator hoax atau kebenaran
5. **Kata Kunci**: Berikan 2-3 kata kunci penting untuk fact-checking (pisahkan dengan koma)

Format jawaban Anda dengan jelas dan gunakan emoji untuk memudahkan pembacaan.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', _imageBytes!),
        ])
      ];

      final response = await model.generateContent(content);
      final analysisResult = response.text ?? 'Tidak dapat menganalisis gambar.';

      // Extract keywords untuk fact-check
      String factCheckResults = "";
      if (analysisResult.contains("Kata Kunci:")) {
        final keywordSection = analysisResult.split("Kata Kunci:").last;
        final keywords = keywordSection.split('\n').first.trim();
        
        // Lakukan fact-check dengan keywords
        factCheckResults = await _checkFactWithGoogle(keywords);
      }

      _showAnalysisResult(analysisResult + "\n\n---\n\n" + factCheckResults);
    } catch (e) {
      _showErrorSnackBar('Gagal menganalisis gambar: $e');
    } finally {
      setState(() {
        _selectedImage = null;
        _imageBytes = null;
      });
    }
  }

  void _showAnalysisResult(String result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.verified_user, color: Color(0xFF76BC6B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Hasil Analisis",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF76BC6B),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              result,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF76BC6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Tutup",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // --- UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             // Pastikan file assets/maskot.png ada di project Anda dan terdaftar di pubspec.yaml
             // Jika tidak ada, comment baris ini:
            // Image.asset(
            //   'assets/maskot.png',
            //   gaplessPlayback: true,
            //   width: 30,
            //   height: 30,
            // ),
            const SizedBox(width: 8),
            Text(
              "BusterHoax",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF76BC6B),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF76BC6B)),
            onPressed: _showImageSourceDialog,
            tooltip: "Upload Gambar Berita",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LlmChatView(
              // Fix 1: Added comma here
              welcomeMessage:
                  "Halo! Saya Chatbot BusterHoax🤖, asisten Anda untuk mendeteksi berita hoax.\n\n"
                  "Saya dapat membantu Anda dengan:\n"
                  "✅ Menganalisis teks berita\n"
                  "📸 Memeriksa screenshot berita (tekan ikon kamera di atas)\n"
                  "Kirim berita yang ingin Anda cek!",

              // Fix 2: Cleaned up GeminiProvider (Removed invalid onRequest/onResponse)
              provider: GeminiProvider(
                model: GenerativeModel(
                  model: "gemini-2.0-flash",
                  apiKey: _geminiApiKey,
                  systemInstruction: Content.system(
                    "Anda adalah 'BusterHoax Bot', ahli deteksi berita hoax. "
                    "Gunakan Google Search tool yang tersedia untuk memverifikasi SETIAP klaim berita. "
                    "Jika menemukan berita, sertakan link sumbernya di jawaban Anda. "
                    "Ketika pengguna mengirim teks berita, Anda harus:\n"
                    "1. Menganalisis berita untuk menentukan apakah itu hoax atau benar\n"
                    "2. Memberikan penjelasan detail dengan:\n"
                    "   - Status: HOAX / BENAR / TIDAK DAPAT DIVERIFIKASI\n"
                    "   - Alasan dan bukti pendukung\n"
                    "   - Tanda-tanda yang ditemukan\n"
                    "3. Menyediakan tips untuk mengenali hoax\n"
                    "4. Memberikan sumber referensi terpercaya\n\n"
                    "Gunakan bahasa Indonesia yang mudah dipahami, objektif, dan profesional. "
                    "Jika pengguna bertanya di luar topik verifikasi berita, jawab dengan sopan: "
                    "'Maaf, saya khusus membantu verifikasi berita dan deteksi hoax. Silakan kirim berita yang ingin Anda cek!'\n\n"
                    "Gunakan emoji secara tepat untuk meningkatkan keterbacaan (🔍 untuk analisis, ✅ untuk benar, ❌ untuk hoax, ⚠️ untuk peringatan)."
                  ),
                ),
              ),

              // Fix 3: Corrected Styling classes
              style: LlmChatViewStyle(
                backgroundColor: const Color(0xFFF5F6FA),
                
                // Style untuk pesan Bot
                llmMessageStyle: LlmMessageStyle(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // textStyle property might be part of markdownStyle in newer versions
                  // or handled automatically. Adding basic check:
                ),
                
                // Style untuk pesan User
                userMessageStyle: UserMessageStyle(
                  decoration: BoxDecoration(
                    color: const Color(0xFF76BC6B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}