import 'package:flutter/material.dart';

import '../models/product.dart';
import 'home_page.dart' show GambarProduk;

class DetailPage extends StatelessWidget {
  final Product produk;

  const DetailPage({super.key, required this.produk});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(produk.nama),
        backgroundColor: tema.colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 260,
              width: double.infinity,
              child: GambarProduk(produk: produk),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produk.nama,
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    produk.hargaRupiah,
                    style: tema.textTheme.titleLarge?.copyWith(
                      color: tema.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text(produk.kategori)),
                  const Divider(height: 32),
                  Text('Deskripsi', style: tema.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(produk.deskripsi, style: tema.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Tambah ke keranjang'),
            onPressed: () {
              // TODO (issue #2): sambungkan ke logika keranjang milik temanmu.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${produk.nama} ditambahkan')),
              );
            },
          ),
        ),
      ),
    );
  }
}
