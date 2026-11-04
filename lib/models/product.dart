import 'package:flutter/material.dart';

class Product {
  final int id;
  final String nama;
  final int harga;
  final String kategori;
  final String deskripsi;

  /// Path gambar asset (misal 'assets/images/sanjai.jpg').
  /// Kalau kosong, tampilan memakai ikon kategori sebagai pengganti.
  final String gambar;

  const Product({
    required this.id,
    required this.nama,
    required this.harga,
    required this.kategori,
    required this.deskripsi,
    this.gambar = '',
  });

  /// Contoh: 35000 -> "Rp 35.000"
  String get hargaRupiah {
    final angka = harga.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
    return 'Rp $angka';
  }

  IconData get ikon {
    switch (kategori) {
      case 'Keripik & Kerupuk':
        return Icons.cookie;
      case 'Lauk Kemasan':
        return Icons.dinner_dining;
      case 'Kue & Camilan':
        return Icons.bakery_dining;
      case 'Minuman':
        return Icons.local_cafe;
      case 'Kerajinan':
        return Icons.checkroom;
      default:
        return Icons.shopping_bag;
    }
  }
}
