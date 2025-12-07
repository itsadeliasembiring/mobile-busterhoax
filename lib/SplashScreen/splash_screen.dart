import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:busterhoax/Menu/menu.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  
  // Durasi sebagai konstanta
  static const Duration _fadeDuration = Duration(milliseconds: 500);
  static const Duration _initialDelay = Duration(milliseconds: 500);
  static const Duration _splashDelay = Duration(seconds: 3); // Durasi tampil splash

  @override
  void initState() {
    super.initState();
    
    // Fade in animasi
    Future.delayed(_initialDelay, () {
      if (!mounted) return;
      setState(() {
        _opacity = 1.0;
      });
    });

    // Otomatis pindah ke Menu setelah delay
    Future.delayed(_splashDelay, () {
      if (!mounted) return;
      _goToMenu();
    });
  }

  void _goToMenu() {
    setState(() {
      _opacity = 0.0;
    });
    
    Future.delayed(_fadeDuration, () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Menu()), // Hapus const
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _goToMenu,
        child: AnimatedOpacity(
          duration: _fadeDuration,
          opacity: _opacity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/maskot.png',
                  gaplessPlayback: true,
                  width: 276,
                  height: 276,
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Text(
                    'BusterHoax',
                    style: GoogleFonts.montserrat(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),
                // Transform.translate(
                //   offset: const Offset(0, -30),
                //   child: Text(
                //     '"Our Planet in Your Hands"',
                //     style: GoogleFonts.montserrat(
                //       fontSize: 16,
                //       color: Colors.black,
                //       fontStyle: FontStyle.italic,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}