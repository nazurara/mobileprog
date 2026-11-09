import 'package:flutter/material.dart';

import '../models/product.dart';

class DetailPage extends StatelessWidget {
  final Product produk;

  const DetailPage({super.key, required this.produk});

  void _tambahKeKeranjang(BuildContext context) {
    // TODO (issue #2): sambungkan ke logika keranjang milik temanmu.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${produk.nama} ditambahkan ke keranjang'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: tema.colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final foto = _FotoProduk(produk: produk);
                  final info = _InfoProduk(produk: produk);

                  // Layar lebar: foto di kiri, info di kanan.
                  if (constraints.maxWidth >= 700) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: foto),
                        const SizedBox(width: 32),
                        Expanded(flex: 6, child: info),
                      ],
                    );
                  }

                  // Layar sempit (HP): foto di atas, info di bawah.
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [foto, const SizedBox(height: 20), info],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 912),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 52),
                  ),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Tambah ke keranjang'),
                  onPressed: () => _tambahKeKeranjang(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Foto produk dalam kartu, ditampilkan utuh (tidak terpotong).
class _FotoProduk extends StatelessWidget {
  final Product produk;

  const _FotoProduk({required this.produk});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    Widget ikon() => Container(
      color: tema.colorScheme.primaryContainer,
      child: Center(
        child: Icon(produk.ikon, size: 80, color: tema.colorScheme.primary),
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: produk.gambar.isNotEmpty
            ? Container(
                color: Colors.white,
                child: Image.asset(
                  produk.gambar,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => ikon(),
                ),
              )
            : ikon(),
      ),
    );
  }
}

/// Kategori, nama, harga, dan deskripsi produk.
class _InfoProduk extends StatelessWidget {
  final Product produk;

  const _InfoProduk({required this.produk});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label kategori
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E2B3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(produk.ikon, size: 16, color: tema.colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(produk.kategori, style: tema.textTheme.labelLarge),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Nama
        Text(
          produk.nama,
          style: tema.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),

        // Harga
        Text(
          produk.hargaRupiah,
          style: tema.textTheme.headlineSmall?.copyWith(
            color: tema.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Divider(height: 36),

        // Deskripsi
        Row(
          children: [
            Icon(Icons.description_outlined, color: tema.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Deskripsi',
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          produk.deskripsi,
          style: tema.textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
