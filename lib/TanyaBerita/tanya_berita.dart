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
  final String _geminiApiKey = "AIzaSyBNJhCA_OmTbfofjEVOUCFcV_sEuxDOs-0"; 
  final String _factCheckApiKey = "AIzaSyBNJhCA_OmTbfofjEVOUCFcV_sEuxDOs-0"; 

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
            if (count >= 3) break;
            
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
2. **Ringkasan Berita**
3. **Alasan Detail**
4. **Tanda-tanda yang Ditemukan**
5. **Kata Kunci** (pisahkan dengan koma)
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', _imageBytes!),
        ])
      ];

      final response = await model.generateContent(content);
      final analysisResult = response.text ?? 'Tidak dapat menganalisis gambar.';

      debugPrint("=== AI RESULT START ===\n$analysisResult\n=== END ===");

      // --- NORMALISASI TEKS ---
      final normalized = analysisResult.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

      // --- DETEKSI HOAX (Improved) ---
      final isHoax = normalized.contains('status') && normalized.contains('hoax') ||
                     normalized.contains('❌') ||
                     normalized.contains('terdeteksi hoax') ||
                     normalized.contains('berita ini hoax') ||
                     normalized.contains('status: hoax');

      // --- FACT CHECK ---
      String factCheckResults = "";
      if (analysisResult.contains("Kata Kunci")) {
        final keywordSection = analysisResult.split("Kata Kunci").last;
        final keywords = keywordSection.split("\n").first.trim();
        factCheckResults = await _checkFactWithGoogle(keywords);
      }

      final finalOutput = "$analysisResult\n\n---\n\n$factCheckResults";

      if (!mounted) return;

      // --- TAMPILKAN HASIL ---
      if (isHoax) {
        _showAnalysisResultWithReportOption(
          finalOutput,
          analysisResult,
          analysisResult,
        );
      } else {
        _showAnalysisResult(finalOutput);
      }
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

  // Dialog analisis dengan opsi laporan (untuk hoax)
  void _showAnalysisResultWithReportOption(String result, String beritaText, String aiAnalysis) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Hasil Analisis",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF76BC6B),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Color(0xFF76BC6B), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Apakah Anda ingin melaporkan berita hoax ini?',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Color(0xFF76BC6B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Tutup",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToReportPage(beritaText, aiAnalysis);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Laporkan",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Navigasi ke halaman laporkan berita dengan data
  void _navigateToReportPage(String beritaText, String aiAnalysis) {
    Navigator.of(context).pushNamed(
      '/laporkan-berita',
      arguments: {
        'judulBerita': 'Berita dari Chat',
        'kontenBerita': beritaText,
        'alasanAI': aiAnalysis,
      },
    );
  }

  // Fungsi untuk membuka halaman laporkan berita kosong
  void _openReportPage() {
    Navigator.of(context).pushNamed('/laporkan-berita');
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
            const SizedBox(width: 8),
            Text(
              "BusterHoax Chatbot",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF76BC6B),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Tombol Laporkan Berita
          // IconButton(
          //   icon: const Icon(Icons.new_releases_outlined, color: Colors.orange),
          //   onPressed: _openReportPage,
          //   tooltip: "Laporkan Berita Hoax",
          // ),
        ],
      ),
      body: Column(
        children: [
          // Banner Info Laporan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.orange.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF76BC6B), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Temukan berita hoax? Tekan menu "Laporkan Berita" untuk melaporkannya!',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(0xFF76BC6B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LlmChatView(
              
              welcomeMessage:
                  "Halo! \n\nSaya Chatbot BusterHoax🤖 \n\n\n Asisten Anda untuk mendeteksi berita hoax.\n\n\n\n\n\n"
                  "Saya dapat membantu Anda dengan:\n\n"
                  "✅ Menganalisis teks berita\n\n\n"
                  "📸 Memeriksa screenshot berita \n\n\n"
                  "📋 Laporkan berita hoax \n\n\n\n\n\n"
                  "silahkan kirim berita yang anda ingin cek melalui \nlink atau gambar!",

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
                    "JIKA STATUS: HOAX, di akhir response tambahkan kalimat:\n"
                    "'⚠️ Berita ini terdeteksi hoax. Anda dapat melaporkan berita ini dengan menekan ikon laporan di atas.'\n\n"
                    "Gunakan bahasa Indonesia yang mudah dipahami, objektif, dan profesional. "
                    "Jika pengguna bertanya di luar topik verifikasi berita, jawab dengan sopan: "
                    "'Maaf, saya khusus membantu verifikasi berita dan deteksi hoax. Silakan kirim berita yang ingin Anda cek!'\n\n"
                    "Gunakan emoji secara tepat untuk meningkatkan keterbacaan (🔍 untuk analisis, ✅ untuk benar, ❌ untuk hoax, ⚠️ untuk peringatan)."
                  ),
                ),
              ),

              style: LlmChatViewStyle(
                backgroundColor: const Color(0xFFF5F6FA),
                
                llmMessageStyle: LlmMessageStyle(
                  icon: Icons.android,
                  iconColor: Colors.white,
                  iconDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                
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