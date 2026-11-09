import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/product.dart';

/// Tambah produk ke keranjang + tampilkan notifikasi dengan tombol LIHAT.
/// Dipakai di home_page.dart dan detail_page.dart.
void tambahKeKeranjang(BuildContext context, Product produk) {
  CartModel.instance.tambah(produk);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${produk.nama} masuk keranjang'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'LIHAT',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KeranjangPage()),
          ),
        ),
      ),
    );
}

/// Ikon keranjang + badge jumlah barang, untuk ditaruh di AppBar.
class TombolKeranjang extends StatelessWidget {
  const TombolKeranjang({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartModel.instance,
      builder: (context, _) {
        final jumlah = CartModel.instance.totalItem;
        return IconButton(
          tooltip: 'Keranjang',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KeranjangPage()),
          ),
          icon: Badge(
            isLabelVisible: jumlah > 0,
            label: Text('$jumlah'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        );
      },
    );
  }
}

class KeranjangPage extends StatelessWidget {
  const KeranjangPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartModel.instance;
    final tema = Theme.of(context);

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Keranjang'),
            backgroundColor: tema.colorScheme.inversePrimary,
            actions: [
              if (!cart.kosong)
                IconButton(
                  tooltip: 'Kosongkan keranjang',
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _konfirmasiKosongkan(context, cart),
                ),
            ],
          ),
          body: cart.kosong ? const _KeranjangKosong() : _daftarItem(cart, tema),
          bottomNavigationBar:
              cart.kosong ? null : _barTotal(context, cart, tema),
        );
      },
    );
  }

  Widget _daftarItem(CartModel cart, ThemeData tema) {
    final items = cart.items;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = items[i];
        final p = item.produk;

        return Dismissible(
          key: ValueKey(p.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => cart.hapus(p),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: tema.colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.delete, color: tema.colorScheme.onError),
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Gambar kecil 64x64
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: _Thumbnail(produk: p),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nama,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.hargaRupiah,
                          style: TextStyle(
                            color: tema.colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatRupiah(item.subtotal),
                          style: TextStyle(
                            color: tema.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.outlined(
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: () => cart.kurang(p),
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${item.jumlah}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: () => cart.tambah(p),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _barTotal(BuildContext context, CartModel cart, ThemeData tema) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: tema.colorScheme.surface,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total (${cart.totalItem} barang)',
                    style: TextStyle(
                      color: tema.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    formatRupiah(cart.totalHarga),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => _checkout(context, cart),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }

  void _checkout(BuildContext context, CartModel cart) {
    final total = formatRupiah(cart.totalHarga);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pesanan Dibuat'),
        content: Text(
          'Terima kasih sudah belanja oleh-oleh Sumbar!\n\nTotal pembayaran: $total',
        ),
        actions: [
          TextButton(
            onPressed: () {
              cart.kosongkan();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _konfirmasiKosongkan(BuildContext context, CartModel cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan keranjang?'),
        content: const Text('Semua barang di keranjang akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              cart.kosongkan();
              Navigator.pop(ctx);
            },
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }
}

/// Gambar kecil produk. Kalau belum ada gambar, tampil ikon kategori.
class _Thumbnail extends StatelessWidget {
  final Product produk;

  const _Thumbnail({required this.produk});

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme.primaryContainer;

    final placeholder = Container(
      color: warna,
      alignment: Alignment.center,
      child: Icon(produk.ikon, size: 30),
    );

    if (produk.gambar.isEmpty) return placeholder;

    return Image.asset(
      produk.gambar,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _KeranjangKosong extends StatelessWidget {
  const _KeranjangKosong();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: tema.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text('Keranjang masih kosong', style: tema.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Yuk pilih oleh-oleh khas Sumbar!',
            style: TextStyle(color: tema.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}