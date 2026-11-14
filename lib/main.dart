import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/profil_page.dart';

// =====================================================================
//  PALET LAPAKKU (sama dengan halaman tracking dan riwayat):
//  marun songket, emas, dan krem hangat.
// =====================================================================
const Color warnaMarun = Color(0xFF8B1E2D);
const Color warnaMarunTua = Color(0xFF5E1520);
const Color warnaEmas = Color(0xFFB8860B);
const Color warnaEmasTerang = Color(0xFFD4AF37);
const Color warnaEmasMuda = Color(0xFFF3E2B3);
const Color warnaKrem = Color(0xFFF7F2EE);

void main() => runApp(const LapakKuApp());

class LapakKuApp extends StatelessWidget {
  const LapakKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final skema = ColorScheme.fromSeed(seedColor: warnaMarun).copyWith(
      secondary: warnaEmas,
      tertiary: warnaEmasTerang,
      // AppBar di semua halaman memakai inversePrimary, jadi dibuat marun.
      inversePrimary: warnaMarun,
      // Label ukuran, placeholder gambar, dan kotak bank bernuansa emas.
      primaryContainer: warnaEmasMuda,
      onPrimaryContainer: warnaMarunTua,
      // Kartu putih bersih seperti di halaman tracking.
      surfaceContainerLow: Colors.white,
    );

    return MaterialApp(
      title: 'LapakKu',
      debugShowCheckedModeBanner: false,
      // Daftar yang bisa digeser juga bisa diseret dengan mouse di Chrome.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: skema,
        scaffoldBackgroundColor: warnaKrem,

        // AppBar marun dengan sudut bawah melengkung dan bayangan lembut.
        appBarTheme: const AppBarTheme(
          backgroundColor: warnaMarun,
          foregroundColor: Colors.white,
          elevation: 4,
          scrolledUnderElevation: 4,
          shadowColor: Color(0x338B1E2D),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
        ),

        // Tombol berbentuk pil: terisi marun, garis tepi emas.
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            foregroundColor: warnaMarun,
            side: const BorderSide(color: Color(0xB3B8860B), width: 1.2),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: warnaMarun),
        ),

        // Filter kategori: putih, garis emas, terpilih emas muda.
        chipTheme: const ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: warnaEmasMuda,
          checkmarkColor: warnaMarun,
          shape: StadiumBorder(),
          side: BorderSide(color: Color(0x66B8860B)),
        ),

        // Badge angka (keranjang, riwayat) berwarna emas.
        badgeTheme: const BadgeThemeData(
          backgroundColor: warnaEmas,
          textColor: Colors.white,
        ),

        // Kolom isian putih supaya kontras dengan latar krem.
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
        ),

        dividerTheme: const DividerThemeData(
          color: Color(0xFFEDE5DE),
          thickness: 1,
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: warnaEmas,
          linearTrackColor: Color(0xFFEADFC8),
        ),

        // Notifikasi mengambang, gelap kemerahan, tombol aksi emas.
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF3A1A1F),
          contentTextStyle: TextStyle(color: Colors.white),
          actionTextColor: Color(0xFFFFD54F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// =====================================================================
//  NAVIGASI UTAMA: menu bawah berbentuk pil melayang (Beranda, Profil)
// =====================================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack menjaga kolom pencarian dan posisi scroll saat pindah tab.
      body: IndexedStack(
        index: _tab,
        children: const [
          HomePage(),
          ProfilPage(sebagaiTab: true),
        ],
      ),
      bottomNavigationBar: _MenuBawah(
        terpilih: _tab,
        onPilih: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// Menu bawah berbentuk pil yang melayang di atas latar krem.
class _MenuBawah extends StatelessWidget {
  final int terpilih;
  final ValueChanged<int> onPilih;

  const _MenuBawah({required this.terpilih, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: warnaKrem,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0x66B8860B)),
                  boxShadow: [
                    BoxShadow(
                      color: warnaMarun.withValues(alpha: 0.14),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _Butir(
                      ikon: Icons.storefront_outlined,
                      ikonAktif: Icons.storefront,
                      label: 'Beranda',
                      aktif: terpilih == 0,
                      onTap: () => onPilih(0),
                    ),
                    _Butir(
                      ikon: Icons.person_outline,
                      ikonAktif: Icons.person,
                      label: 'Profil',
                      aktif: terpilih == 1,
                      onTap: () => onPilih(1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu pilihan di menu bawah: tab aktif melebar jadi pil emas muda.
class _Butir extends StatelessWidget {
  final IconData ikon;
  final IconData ikonAktif;
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  const _Butir({
    required this.ikon,
    required this.ikonAktif,
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: 48,
            decoration: BoxDecoration(
              color: aktif ? warnaEmasMuda : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  aktif ? ikonAktif : ikon,
                  size: 22,
                  color: aktif ? warnaMarun : Colors.black54,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: aktif
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: warnaMarun,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}