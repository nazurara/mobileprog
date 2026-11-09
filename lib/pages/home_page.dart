import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../models/product.dart';
import 'detail_page.dart';
import 'keranjang_page.dart';

/// ID produk yang diberi label "Terlaris".
const Set<int> _idTerlaris = {1, 4, 9};

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scroll = ScrollController();
  String _kataKunci = '';
  String _kategoriDipilih = 'Semua';
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Menghitung seberapa jauh daftar produk sudah digeser (untuk bar di bawah).
  void _updateProgress() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final total = pos.maxScrollExtent + pos.viewportDimension;
    final nilai = total <= 0
        ? 1.0
        : (pos.pixels + pos.viewportDimension) / total;
    final bersih = nilai.clamp(0.0, 1.0);
    if ((bersih - _progress).abs() > 0.001) {
      setState(() => _progress = bersih);
    }
  }

  List<Product> get _produkTampil {
    return daftarProduk.where((p) {
      final cocokKategori =
          _kategoriDipilih == 'Semua' || p.kategori == _kategoriDipilih;
      final cocokCari = p.nama.toLowerCase().contains(_kataKunci.toLowerCase());
      return cocokKategori && cocokCari;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final produk = _produkTampil;
    final tema = Theme.of(context);

    // Hitung ulang bar geser setelah tampilan selesai digambar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateProgress();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('LapakKu'),
        backgroundColor: tema.colorScheme.inversePrimary,
        actions: const [TombolKeranjang(), SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 28),

            // Judul
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Oleh-oleh '),
                    TextSpan(
                      text: 'Khas Minang',
                      style: TextStyle(color: tema.colorScheme.primary),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: tema.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Pilih oleh-oleh terbaik dari Ranah Minang '
                '(geser ke samping untuk melihat produk lainnya)',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Kolom pencarian
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: TextField(
                  onChanged: (nilai) => setState(() => _kataKunci = nilai),
                  decoration: InputDecoration(
                    hintText: 'Cari oleh-oleh...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter kategori
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final kategori in daftarKategori)
                    ChoiceChip(
                      label: Text(kategori),
                      selected: _kategoriDipilih == kategori,
                      onSelected: (_) =>
                          setState(() => _kategoriDipilih = kategori),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daftar produk (geser ke samping)
            if (produk.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Text('Produk tidak ditemukan'),
              )
            else ...[
              SizedBox(
                height: 450,
                child: ScrollConfiguration(
                  // Supaya bisa digeser dengan mouse di Chrome.
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: ListView.separated(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: produk.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 16),
                    itemBuilder: (context, i) =>
                        _KartuProduk(produk: produk[i]),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Bar penanda posisi geser
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: tema.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _KartuProduk extends StatelessWidget {
  final Product produk;

  const _KartuProduk({required this.produk});

  void _bukaDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPage(produk: produk)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto + label "Terlaris"
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 170,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GambarProduk(produk: produk),
                      if (_idTerlaris.contains(produk.id))
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tema.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: tema.colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Terlaris',
                                  style: TextStyle(
                                    color: tema.colorScheme.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nama (tinggi tetap supaya semua kartu rata)
              SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    produk.nama,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                produk.kategori,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // Harga
              Text(
                produk.hargaRupiah,
                textAlign: TextAlign.center,
                style: tema.textTheme.titleLarge?.copyWith(
                  color: tema.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Tombol keranjang
              FilledButton.icon(
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Tambah ke keranjang'),
                onPressed: () => tambahKeKeranjang(context, produk),
              ),
              const SizedBox(height: 8),

              // Tombol detail
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Detail Produk'),
                onPressed: () => _bukaDetail(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menampilkan gambar produk. Kalau belum ada gambar, tampil ikon kategori.
class GambarProduk extends StatelessWidget {
  final Product produk;

  const GambarProduk({super.key, required this.produk});

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme.primaryContainer;

    if (produk.gambar.isNotEmpty) {
      return Image.asset(
        produk.gambar,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(warna),
      );
    }
    return _placeholder(warna);
  }

  Widget _placeholder(Color warna) {
    return Container(
      width: double.infinity,
      color: warna,
      child: Icon(produk.ikon, size: 56),
    );
  }
}