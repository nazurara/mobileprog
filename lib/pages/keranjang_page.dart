import 'package:flutter/material.dart';

import '../models/product.dart';

// =====================================================================
//  KERANJANG + CHECKOUT (gaya Shopee) - semuanya ada di SATU file ini.
//  Isi file:
//   1. formatRupiah        -> ubah angka jadi "Rp 35.000"
//   2. CartModel           -> data keranjang (tidak perlu cart.dart lagi)
//   3. tambahKeKeranjang   -> dipakai tombol "Tambah ke keranjang"
//   4. TombolKeranjang     -> ikon keranjang + badge di AppBar
//   5. KeranjangPage       -> halaman keranjang (centang, jumlah, total)
//   6. CheckoutPage        -> alamat, pengiriman, pembayaran, rincian
//   7. PesananBerhasilPage -> halaman setelah "Buat Pesanan"
// =====================================================================

/// Contoh: 35000 -> "Rp 35.000"
String formatRupiah(int angka) {
  final teks = angka.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => '.',
  );
  return 'Rp $teks';
}

// ---------------------------------------------------------------------
//  DATA KERANJANG
// ---------------------------------------------------------------------

class CartItem {
  final Product produk;
  int jumlah;
  bool dipilih;

  CartItem({required this.produk, this.jumlah = 1, this.dipilih = true});

  int get subtotal => produk.harga * jumlah;
}

class CartModel extends ChangeNotifier {
  CartModel._();
  static final CartModel instance = CartModel._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  bool get kosong => _items.isEmpty;

  /// Jumlah semua barang di keranjang (untuk badge).
  int get totalItem => _items.fold(0, (s, i) => s + i.jumlah);

  /// Barang yang dicentang.
  List<CartItem> get itemDipilih => _items.where((i) => i.dipilih).toList();
  int get jumlahDipilih => itemDipilih.fold(0, (s, i) => s + i.jumlah);
  int get totalDipilih => itemDipilih.fold(0, (s, i) => s + i.subtotal);
  bool get semuaDipilih => _items.isNotEmpty && _items.every((i) => i.dipilih);

  int _cari(Product p) => _items.indexWhere((i) => i.produk.id == p.id);

  void tambah(Product p) {
    final idx = _cari(p);
    if (idx == -1) {
      _items.insert(0, CartItem(produk: p));
    } else {
      _items[idx].jumlah++;
    }
    notifyListeners();
  }

  void kurang(Product p) {
    final idx = _cari(p);
    if (idx == -1) return;
    if (_items[idx].jumlah > 1) {
      _items[idx].jumlah--;
      notifyListeners();
    }
  }

  void toggle(Product p) {
    final idx = _cari(p);
    if (idx == -1) return;
    _items[idx].dipilih = !_items[idx].dipilih;
    notifyListeners();
  }

  void pilihSemua(bool nilai) {
    for (final i in _items) {
      i.dipilih = nilai;
    }
    notifyListeners();
  }

  void hapus(Product p) {
    _items.removeWhere((i) => i.produk.id == p.id);
    notifyListeners();
  }

  /// Dipanggil setelah pesanan dibuat: barang yang dicentang dihapus.
  void hapusDipilih() {
    _items.removeWhere((i) => i.dipilih);
    notifyListeners();
  }
}

// ---------------------------------------------------------------------
//  TOMBOL-TOMBOL YANG DIPAKAI HALAMAN LAIN
// ---------------------------------------------------------------------

/// Tambah produk ke keranjang + notifikasi dengan tombol LIHAT.
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

// ---------------------------------------------------------------------
//  HALAMAN KERANJANG
// ---------------------------------------------------------------------

class KeranjangPage extends StatelessWidget {
  const KeranjangPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartModel.instance;

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(title: Text('Keranjang Saya (${cart.totalItem})')),
          body: cart.kosong
              ? const _KeranjangKosong()
              : _isiKeranjang(context, cart),
          bottomNavigationBar: cart.kosong ? null : _BarCheckout(cart: cart),
        );
      },
    );
  }

  Widget _isiKeranjang(BuildContext context, CartModel cart) {
    final tema = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      children: [
        // Header toko (centang = pilih semua)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
          child: Row(
            children: [
              Checkbox(
                value: cart.semuaDipilih,
                onChanged: (v) => cart.pilihSemua(v ?? false),
              ),
              Icon(Icons.storefront, size: 20, color: tema.colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Toko Oleh-Oleh Minang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        for (final item in cart.items) _BarisItem(item: item, cart: cart),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Geser barang ke kiri untuk menghapus',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarisItem extends StatelessWidget {
  final CartItem item;
  final CartModel cart;

  const _BarisItem({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    final p = item.produk;
    final tema = Theme.of(context);

    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cart.hapus(p),
      background: Container(
        color: tema.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 1),
        padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: item.dipilih, onChanged: (_) => cart.toggle(p)),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 84,
                height: 84,
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
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.kategori,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.hargaRupiah,
                    style: TextStyle(
                      color: tema.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _Stepper(item: item, cart: cart),
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

/// Tombol  -  [jumlah]  +  seperti di Shopee.
class _Stepper extends StatelessWidget {
  final CartItem item;
  final CartModel cart;

  const _Stepper({required this.item, required this.cart});

  Future<void> _kurang(BuildContext context) async {
    if (item.jumlah > 1) {
      cart.kurang(item.produk);
      return;
    }
    final hapus = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('Hapus ${item.produk.nama} dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (hapus == true) cart.hapus(item.produk);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TombolStep(icon: Icons.remove, onTap: () => _kurang(context)),
          Container(
            width: 36,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: Colors.black26),
              ),
            ),
            child: Text(
              '${item.jumlah}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _TombolStep(icon: Icons.add, onTap: () => cart.tambah(item.produk)),
        ],
      ),
    );
  }
}

class _TombolStep extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TombolStep({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 16)),
    );
  }
}

/// Bar bawah: [ ] Semua   Total Rp xxx   [Checkout (n)]
class _BarCheckout extends StatelessWidget {
  final CartModel cart;

  const _BarCheckout({required this.cart});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final aktif = cart.jumlahDipilih > 0;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Checkbox(
              value: cart.semuaDipilih,
              onChanged: (v) => cart.pilihSemua(v ?? false),
            ),
            const Text('Semua'),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  Text(
                    formatRupiah(cart.totalDipilih),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: aktif
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutPage()),
                    )
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text('Checkout (${cart.jumlahDipilih})'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeranjangKosong extends StatelessWidget {
  const _KeranjangKosong();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 90,
            color: Colors.black26,
          ),
          const SizedBox(height: 12),
          const Text(
            'Keranjang belanjamu masih kosong',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Yuk pilih oleh-oleh khas Minang!',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Belanja Sekarang'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  HALAMAN CHECKOUT
// ---------------------------------------------------------------------

class _Kurir {
  final String nama;
  final String estimasi;
  final int biaya;

  const _Kurir(this.nama, this.estimasi, this.biaya);
}

const List<_Kurir> _daftarKurir = [
  _Kurir('Hemat', 'Estimasi tiba 5-7 hari', 10000),
  _Kurir('Reguler', 'Estimasi tiba 3-4 hari', 20000),
  _Kurir('Kilat', 'Estimasi tiba 1-2 hari', 35000),
];

class _MetodeBayar {
  final String nama;
  final IconData ikon;

  const _MetodeBayar(this.nama, this.ikon);
}

const List<_MetodeBayar> _daftarBayar = [
  _MetodeBayar('COD (Bayar di Tempat)', Icons.payments_outlined),
  _MetodeBayar('Transfer Bank', Icons.account_balance_outlined),
  _MetodeBayar(
    'E-Wallet (DANA / OVO / GoPay)',
    Icons.account_balance_wallet_outlined,
  ),
  _MetodeBayar('QRIS', Icons.qr_code_2),
];

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const int _biayaLayanan = 1000;

  late final List<CartItem> _barang;
  final TextEditingController _catatan = TextEditingController();

  String _nama = '';
  String _telp = '';
  String _alamat = '';
  int _kurir = 1;
  int _bayar = 0;

  @override
  void initState() {
    super.initState();
    // Salinan barang yang dicentang di keranjang.
    _barang = CartModel.instance.itemDipilih
        .map((i) => CartItem(produk: i.produk, jumlah: i.jumlah))
        .toList();
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  int get _jumlahBarang => _barang.fold(0, (s, i) => s + i.jumlah);
  int get _subtotalProduk => _barang.fold(0, (s, i) => s + i.subtotal);
  int get _ongkir => _daftarKurir[_kurir].biaya;
  int get _total => _subtotalProduk + _ongkir + _biayaLayanan;
  bool get _alamatLengkap =>
      _nama.isNotEmpty && _telp.isNotEmpty && _alamat.isNotEmpty;

  Future<void> _ubahAlamat() async {
    final hasil = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormAlamat(nama: _nama, telp: _telp, alamat: _alamat),
    );
    if (hasil == null || !mounted) return;
    setState(() {
      _nama = hasil[0];
      _telp = hasil[1];
      _alamat = hasil[2];
    });
  }

  void _buatPesanan() {
    if (!_alamatLengkap) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Lengkapi alamat pengiriman dulu ya')),
        );
      return;
    }

    final noPesanan = 'OSB${DateTime.now().millisecondsSinceEpoch % 100000000}';
    final halamanBerhasil = PesananBerhasilPage(
      noPesanan: noPesanan,
      total: _total,
      metodeBayar: _daftarBayar[_bayar].nama,
      kurir: _daftarKurir[_kurir].nama,
      penerima: '$_nama ($_telp)',
      alamat: _alamat,
    );

    CartModel.instance.hapusDipilih();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => halamanBerhasil),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _kartuAlamat(tema),
          _kartuProduk(tema),
          _kartuKurir(tema),
          _kartuBayar(tema),
          _kartuRincian(tema),
        ],
      ),
      bottomNavigationBar: _barBayar(tema),
    );
  }

  // ----- Alamat -----
  Widget _kartuAlamat(ThemeData tema) {
    return _Kartu(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: _ubahAlamat,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: tema.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: _alamatLengkap
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alamat Pengiriman',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_nama  |  $_telp',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(_alamat),
                        ],
                      )
                    : Text(
                        'Tambahkan alamat pengiriman',
                        style: TextStyle(
                          color: tema.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  // ----- Daftar produk -----
  Widget _kartuProduk(ThemeData tema) {
    return _Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, size: 20, color: tema.colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Toko Oleh-Oleh Minang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final b in _barang)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: _Thumbnail(produk: b.produk),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.produk.nama,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              b.produk.hargaRupiah,
                              style: TextStyle(
                                color: tema.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'x${b.jumlah}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _catatan,
            decoration: const InputDecoration(
              hintText: 'Pesan untuk penjual (opsional)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total $_jumlahBarang produk: ${formatRupiah(_subtotalProduk)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ----- Opsi pengiriman -----
  Widget _kartuKurir(ThemeData tema) {
    return _Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opsi Pengiriman',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (var i = 0; i < _daftarKurir.length; i++)
            _PilihanTile(
              terpilih: _kurir == i,
              onTap: () => setState(() => _kurir = i),
              judul: _daftarKurir[i].nama,
              ket: _daftarKurir[i].estimasi,
              kanan: formatRupiah(_daftarKurir[i].biaya),
            ),
        ],
      ),
    );
  }

  // ----- Metode pembayaran -----
  Widget _kartuBayar(ThemeData tema) {
    return _Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metode Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (var i = 0; i < _daftarBayar.length; i++)
            _PilihanTile(
              terpilih: _bayar == i,
              onTap: () => setState(() => _bayar = i),
              ikon: _daftarBayar[i].ikon,
              judul: _daftarBayar[i].nama,
            ),
        ],
      ),
    );
  }

  // ----- Rincian pembayaran -----
  Widget _kartuRincian(ThemeData tema) {
    return _Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _BarisRincian('Subtotal untuk Produk', formatRupiah(_subtotalProduk)),
          _BarisRincian('Subtotal Pengiriman', formatRupiah(_ongkir)),
          _BarisRincian('Biaya Layanan', formatRupiah(_biayaLayanan)),
          const Divider(height: 24),
          _BarisRincian(
            'Total Pembayaran',
            formatRupiah(_total),
            tebal: true,
            warna: tema.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // ----- Bar bawah -----
  Widget _barBayar(ThemeData tema) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
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
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    formatRupiah(_total),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: _buatPesanan,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Buat Pesanan'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kotak putih untuk tiap bagian di halaman checkout.
class _Kartu extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Kartu({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: Colors.white,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Baris pilihan (pengiriman / pembayaran) dengan tanda centang.
class _PilihanTile extends StatelessWidget {
  final bool terpilih;
  final VoidCallback onTap;
  final IconData? ikon;
  final String judul;
  final String? ket;
  final String? kanan;

  const _PilihanTile({
    required this.terpilih,
    required this.onTap,
    required this.judul,
    this.ikon,
    this.ket,
    this.kanan,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (ikon != null) ...[Icon(ikon), const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (ket != null)
                    Text(
                      ket!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            if (kanan != null)
              Text(kanan!, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(
              terpilih ? Icons.check_circle : Icons.radio_button_unchecked,
              color: terpilih ? tema.colorScheme.primary : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisRincian extends StatelessWidget {
  final String label;
  final String nilai;
  final bool tebal;
  final Color? warna;

  const _BarisRincian(this.label, this.nilai, {this.tebal = false, this.warna});

  @override
  Widget build(BuildContext context) {
    final gaya = TextStyle(
      fontWeight: tebal ? FontWeight.bold : FontWeight.normal,
      fontSize: tebal ? 16 : 14,
      color: warna,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: gaya),
          Text(nilai, style: gaya),
        ],
      ),
    );
  }
}

/// Form isi alamat (muncul dari bawah layar).
class _FormAlamat extends StatefulWidget {
  final String nama;
  final String telp;
  final String alamat;

  const _FormAlamat({
    required this.nama,
    required this.telp,
    required this.alamat,
  });

  @override
  State<_FormAlamat> createState() => _FormAlamatState();
}

class _FormAlamatState extends State<_FormAlamat> {
  final _kunci = GlobalKey<FormState>();
  late final TextEditingController _nama = TextEditingController(
    text: widget.nama,
  );
  late final TextEditingController _telp = TextEditingController(
    text: widget.telp,
  );
  late final TextEditingController _alamat = TextEditingController(
    text: widget.alamat,
  );

  @override
  void dispose() {
    _nama.dispose();
    _telp.dispose();
    _alamat.dispose();
    super.dispose();
  }

  String? _wajib(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _kunci,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alamat Pengiriman',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nama,
                validator: _wajib,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama penerima',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telp,
                validator: _wajib,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _alamat,
                validator: _wajib,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alamat lengkap',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_kunci.currentState!.validate()) {
                      Navigator.pop(context, [
                        _nama.text.trim(),
                        _telp.text.trim(),
                        _alamat.text.trim(),
                      ]);
                    }
                  },
                  child: const Text('Simpan Alamat'),
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
//  HALAMAN PESANAN BERHASIL
// ---------------------------------------------------------------------

class PesananBerhasilPage extends StatelessWidget {
  final String noPesanan;
  final int total;
  final String metodeBayar;
  final String kurir;
  final String penerima;
  final String alamat;

  const PesananBerhasilPage({
    super.key,
    required this.noPesanan,
    required this.total,
    required this.metodeBayar,
    required this.kurir,
    required this.penerima,
    required this.alamat,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 96,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pesanan Berhasil Dibuat!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Terima kasih sudah belanja oleh-oleh khas Minang',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _BarisInfo('No. Pesanan', noPesanan),
                          _BarisInfo('Pembayaran', metodeBayar),
                          _BarisInfo('Pengiriman', kurir),
                          _BarisInfo('Penerima', penerima),
                          _BarisInfo('Alamat', alamat),
                          const Divider(height: 24),
                          _BarisInfo(
                            'Total Pembayaran',
                            formatRupiah(total),
                            warna: tema.colorScheme.primary,
                            tebal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.popUntil(context, (r) => r.isFirst),
                        child: const Text('Kembali ke Beranda'),
                      ),
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

class _BarisInfo extends StatelessWidget {
  final String label;
  final String nilai;
  final bool tebal;
  final Color? warna;

  const _BarisInfo(this.label, this.nilai, {this.tebal = false, this.warna});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              nilai,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: tebal ? FontWeight.bold : FontWeight.w500,
                color: warna,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  GAMBAR KECIL PRODUK (dipakai keranjang & checkout)
// ---------------------------------------------------------------------

class _Thumbnail extends StatelessWidget {
  final Product produk;

  const _Thumbnail({required this.produk});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Theme.of(context).colorScheme.primaryContainer,
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