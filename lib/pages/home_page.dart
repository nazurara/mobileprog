import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../models/product.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _kataKunci = '';
  String _kategoriDipilih = 'Semua';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('LapakKu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Kolom pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (nilai) => setState(() => _kataKunci = nilai),
              decoration: InputDecoration(
                hintText: 'Cari oleh-oleh...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Filter kategori
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: daftarKategori.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final kategori = daftarKategori[i];
                return ChoiceChip(
                  label: Text(kategori),
                  selected: _kategoriDipilih == kategori,
                  onSelected: (_) =>
                      setState(() => _kategoriDipilih = kategori),
                );
              },
            ),
          ),

          // Daftar produk
          Expanded(
            child: produk.isEmpty
                ? const Center(child: Text('Produk tidak ditemukan'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: produk.length,
                    itemBuilder: (context, i) =>
                        _KartuProduk(produk: produk[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KartuProduk extends StatelessWidget {
  final Product produk;

  const _KartuProduk({required this.produk});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailPage(produk: produk)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: GambarProduk(produk: produk)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produk.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    produk.hargaRupiah,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        errorBuilder: (_, _, _) => _placeholder(warna),
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
