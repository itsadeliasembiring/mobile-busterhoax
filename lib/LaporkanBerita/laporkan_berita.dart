import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LaporkanBeritaPage extends StatefulWidget {
  const LaporkanBeritaPage({super.key});

  @override
  State<LaporkanBeritaPage> createState() => _LaporkanBeritaPageState();
}

class _LaporkanBeritaPageState extends State<LaporkanBeritaPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _kontenController = TextEditingController();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _nomorHpController = TextEditingController();
  final _sumberController = TextEditingController();
  final _alasanController = TextEditingController();
  
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _judulController.text = args['judulBerita'] ?? '';
          _kontenController.text = args['kontenBerita'] ?? '';
          _alasanController.text = args['alasanAI'] ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _judulController.dispose();
    _kontenController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _nomorHpController.dispose();
    _sumberController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _submitLaporan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await supabase.from('laporan_hoax').insert({
        'judul_berita': _judulController.text.trim(),
        'konten_berita': _kontenController.text.trim(),
        'sumber': _sumberController.text.trim(),
        'alasan_laporan': _alasanController.text.trim(),
        'nama_pelapor': _namaController.text.trim(),
        'email_pelapor': _emailController.text.trim(),
        'nomor_hp': _nomorHpController.text.trim(),
        'status_verifikasi': 'pending',
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal mengirim laporan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Laporan Terkirim!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Terima kasih! Laporan Anda telah berhasil dikirim dan akan segera diverifikasi oleh tim kami.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF76BC6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          'Laporkan Berita Hoax',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF76BC6B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF76BC6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF76BC6B).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF76BC6B), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bantu kami melawan hoax dengan melaporkan berita yang tidak benar',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Color(0xFF76BC6B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Judul Berita
              _buildTextField(
                controller: _judulController,
                label: 'Judul Berita',
                hint: 'Masukkan judul berita yang ingin dilaporkan',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul berita wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Konten Berita
              _buildTextField(
                controller: _kontenController,
                label: 'Konten Berita',
                hint: 'Masukkan isi berita atau screenshot teks',
                icon: Icons.article,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Konten berita wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sumber Berita
              _buildTextField(
                controller: _sumberController,
                label: 'Sumber Berita',
                hint: 'Contoh: WhatsApp, Facebook, Twitter, dll',
                icon: Icons.source,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sumber berita wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Alasan Laporan
              _buildTextField(
                controller: _alasanController,
                label: 'Alasan Pelaporan',
                hint: 'Jelaskan mengapa berita ini hoax atau menyesatkan',
                icon: Icons.description,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alasan pelaporan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Divider
              const Divider(thickness: 1),
              const SizedBox(height: 8),
              
              Text(
                'Data Pelapor',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),

              // Nama Pelapor
              _buildTextField(
                controller: _namaController,
                label: 'Nama Lengkap',
                hint: 'Masukkan nama Anda',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              _buildTextField(
                controller: _emailController,
                label: 'Email (Opsional)',
                hint: 'email@example.com',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Nomor HP
              _buildTextField(
                controller: _nomorHpController,
                label: 'Nomor HP (Opsional)',
                hint: '08xxxxxxxxxx',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Info Footer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Data Anda aman dan akan digunakan untuk keperluan verifikasi',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLaporan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF76BC6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Kirim Laporan',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(icon, color: Color(0xFF76BC6B), size: 22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF76BC6B), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }
}