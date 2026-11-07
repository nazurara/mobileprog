import 'package:flutter/material.dart';

import 'pages/home_page.dart';

// Palet warna LapakKu (terinspirasi songket dan rendang Minang)
const Color warnaMarun = Color(0xFF8B1E2D);
const Color warnaEmas = Color(0xFFB8860B);
const Color warnaKrem = Color(0xFFFFF8F0);

void main() => runApp(const LapakKuApp());

class LapakKuApp extends StatelessWidget {
  const LapakKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LapakKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Marun sebagai warna utama, emas sebagai aksen.
        // inversePrimary dibuat marun supaya AppBar di semua halaman ikut marun.
        colorScheme: ColorScheme.fromSeed(seedColor: warnaMarun)
            .copyWith(secondary: warnaEmas, inversePrimary: warnaMarun),
        scaffoldBackgroundColor: warnaKrem,
        appBarTheme: const AppBarTheme(foregroundColor: Colors.white),
        chipTheme: const ChipThemeData(
          selectedColor: Color(0xFFF3E2B3),
          checkmarkColor: warnaMarun,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: warnaEmas,
          linearTrackColor: Color(0xFFEADFC8),
        ),
      ),
      home: const HomePage(),
    );
  }
}
