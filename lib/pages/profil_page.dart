import 'package:flutter/material.dart';

import '../widgets/hover_besar.dart';
import 'keranjang_page.dart';
import 'riwayat_pesanan_page.dart';

// =====================================================================
//  HALAMAN PROFIL
//  Sementara menampilkan data aplikasi (jumlah pesanan, keranjang).
//  Nama dan email akan diganti data akun setelah login dibuat.
// =====================================================================

// Warna emas (sama dengan palet di main.dart).
const Color _emas = Color(0xFFB8860B);
const Color _emasTerang = Color(0xFFD4AF37);
const Color _emasMuda = Color(0xFFF3E2B3);

class ProfilPage extends StatelessWidget {
  /// true = dipakai sebagai tab di menu bawah (tanpa tombol kembali).
  final bool sebagaiTab;

  const ProfilPage({super.key, this.sebagaiTab = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Di Chrome, bagian luar kolom ini abu-abu supaya terlihat seperti HP.
      backgroundColor: const Color(0xFFE9E2DC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            color: const Color(0xFFF7F2EE),
            child: ListenableBuilder(
              listenable: Listenable.merge([
                PesananModel.instance,
                CartModel.instance,
              ]),
              builder: (context, _) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const _HeaderProfil(),
                          _statistik(context),
                          _menu(context),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                            child: Text(
                              'Aplikasi demo, pembayaran dan pengiriman simulasi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tombol kembali hanya muncul kalau BUKAN tab.
                    if (!sebagaiTab) _barBawah(context),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ----- Ringkasan angka -----
  Widget _statistik(BuildContext context) {
    final warna = Theme.of(context).colorScheme.primary;
    final pesanan = PesananModel.instance;

    Widget angka(String nilai, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              nilai,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: warna,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return _Kotak(
      child: IntrinsicHeight(
        child: Row(
          children: [
            angka('${pesanan.daftar.length}', 'Pesanan'),
            const VerticalDivider(color: _emasMuda, thickness: 1.5),
            angka('${pesanan.perluBayar}', 'Perlu dibayar'),
            const VerticalDivider(color: _emasMuda, thickness: 1.5),
            angka('${CartModel.instance.totalItem}', 'Di keranjang'),
          ],
        ),
      ),
    );
  }

  // ----- Daftar menu -----
  Widget _menu(BuildContext context) {
    return _Kotak(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _MenuTile(
            ikon: Icons.receipt_long_outlined,
            judul: 'Pesanan Saya',
            ket: 'Lihat riwayat dan lacak pesanan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PesananSayaPage()),
            ),
          ),
          const Divider(height: 1, indent: 72),
          _MenuTile(
            ikon: Icons.shopping_cart_outlined,
            judul: 'Keranjang Saya',
            ket: 'Barang yang belum dibeli',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KeranjangPage()),
            ),
          ),
          const Divider(height: 1, indent: 72),
          // TODO: sambungkan ke halaman masuk/daftar setelah login dibuat.
          _MenuTile(
            ikon: Icons.login_outlined,
            judul: 'Masuk atau Daftar',
            ket: 'Segera hadir',
            onTap: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Fitur masuk segera hadir')),
              ),
          ),
          const Divider(height: 1, indent: 72),
          _MenuTile(
            ikon: Icons.info_outline,
            judul: 'Tentang Aplikasi',
            ket: 'Versi dan informasi',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'LapakKu',
              applicationVersion: '1.0.0 (demo)',
              children: const [
                SizedBox(height: 8),
                Text(
                  'Toko oleh-oleh khas Minang. Pembayaran dan pengiriman '
                  'masih simulasi.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barBawah(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: HoverBesar(
          skala: 1.03,
          child: FilledButton.icon(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Kembali ke Beranda'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  HEADER (avatar dengan cincin emas)
// ---------------------------------------------------------------------

class _HeaderProfil extends StatelessWidget {
  const _HeaderProfil();

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [warna, Color.lerp(warna, Colors.black, 0.3)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            children: [
              // Cincin emas bergradasi
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_emasMuda, _emasTerang, _emas],
                  ),
                ),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(warna, Colors.black, 0.25),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Pengunjung LapakKu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _emasTerang),
                ),
                child: const Text(
                  'Belum masuk',
                  style: TextStyle(
                    color: _emasMuda,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  KOMPONEN KECIL
// ---------------------------------------------------------------------

/// Kotak putih membulat dengan bayangan lembut.
class _Kotak extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Kotak({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Satu baris menu: ikon emas muda, judul, keterangan, panah.
class _MenuTile extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String ket;
  final VoidCallback onTap;

  const _MenuTile({
    required this.ikon,
    required this.judul,
    required this.ket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _emasMuda,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ikon, size: 22, color: warna),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ket,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}