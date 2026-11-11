import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import 'varian_produk.dart';
import 'lacak_pesanan_page.dart';

// =====================================================================
//  KERANJANG + CHECKOUT + PESANAN (gaya Shopee) - SATU file.
//  Isi file:
//   1. Format & helper     -> formatRupiah, tanggal
//   2. CartModel           -> data keranjang (produk + varian ukuran)
//   3. Alamat              -> data alamat + daftar provinsi
//   4. Voucher             -> data voucher
//   5. Pesanan             -> data pesanan (riwayat)
//   6. tambahKeKeranjang / TombolKeranjang -> dipakai halaman lain
//   7. KeranjangPage       -> keranjang (centang, jumlah, hapus, undo)
//   8. CheckoutPage        -> alamat, voucher, kurir, bayar, rincian
//   9. AlamatFormPage      -> form alamat lengkap
//  10. PesananBerhasilPage -> setelah "Buat Pesanan"
//  11. PesananSayaPage     -> riwayat pesanan
// =====================================================================

// ---------------------------------------------------------------------
//  FORMAT & HELPER
// ---------------------------------------------------------------------

/// Contoh: 35000 -> "Rp 35.000"
String formatRupiah(int angka) {
  final teks = angka.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => '.',
  );
  return 'Rp $teks';
}

/// Contoh: "11 Nov 2026, 13:45"
String _formatTanggal(DateTime d) {
  const bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${d.day} ${bulan[d.month - 1]} ${d.year}, ${dua(d.hour)}:${dua(d.minute)}';
}

// ---------------------------------------------------------------------
//  DATA KERANJANG
// ---------------------------------------------------------------------

class CartItem {
  final Product produk;

  /// Ukuran yang dipilih (beserta harganya).
  final Varian varian;
  int jumlah;
  bool dipilih;

  CartItem({
    required this.produk,
    required this.varian,
    this.jumlah = 1,
    this.dipilih = true,
  });

  /// Produk yang sama dengan ukuran berbeda dianggap barang terpisah.
  String get kunci => '${produk.id}|${varian.label}';

  /// Harga satuan sesuai ukuran yang dipilih.
  int get harga => varian.harga;

  int get subtotal => harga * jumlah;
}

class CartModel extends ChangeNotifier {
  CartModel._();
  static final CartModel instance = CartModel._();

  /// Batas pembelian per produk (per ukuran).
  static const int maksPerProduk = 20;

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

  int _cari(String kunci) => _items.indexWhere((i) => i.kunci == kunci);

  /// Posisi barang di keranjang (-1 kalau tidak ada). Untuk fitur batal hapus.
  int indeksDari(CartItem item) => _cari(item.kunci);

  /// Mengembalikan false kalau sudah mencapai batas pembelian.
  bool tambah(Product p, Varian v, {int jumlah = 1}) {
    final kunci = '${p.id}|${v.label}';
    final idx = _cari(kunci);
    if (idx == -1) {
      _items.insert(
        0,
        CartItem(
          produk: p,
          varian: v,
          jumlah: jumlah > maksPerProduk ? maksPerProduk : jumlah,
        ),
      );
    } else {
      if (_items[idx].jumlah >= maksPerProduk) return false;
      final baru = _items[idx].jumlah + jumlah;
      _items[idx].jumlah = baru > maksPerProduk ? maksPerProduk : baru;
    }
    notifyListeners();
    return true;
  }

  void kurang(CartItem item) {
    final idx = _cari(item.kunci);
    if (idx == -1) return;
    if (_items[idx].jumlah > 1) {
      _items[idx].jumlah--;
      notifyListeners();
    }
  }

  void toggle(CartItem item) {
    final idx = _cari(item.kunci);
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

  void hapus(CartItem item) {
    _items.removeWhere((i) => i.kunci == item.kunci);
    notifyListeners();
  }

  /// Mengembalikan barang yang tadi dihapus (tombol BATAL).
  void sisipkan(int index, CartItem item) {
    if (_cari(item.kunci) != -1) return;
    final pos = index > _items.length ? _items.length : index;
    _items.insert(pos, item);
    notifyListeners();
  }

  /// Menghapus semua barang yang dicentang (tombol "Hapus" dan
  /// setelah pesanan dibuat).
  void hapusDipilih() {
    _items.removeWhere((i) => i.dipilih);
    notifyListeners();
  }
}

// ---------------------------------------------------------------------
//  DATA ALAMAT
// ---------------------------------------------------------------------

class Alamat {
  final String nama;
  final String telp;
  final String provinsi;
  final String kota;
  final String kecamatan;
  final String kodePos;
  final String jalan;
  final String detail;
  final String label;

  const Alamat({
    required this.nama,
    required this.telp,
    required this.provinsi,
    required this.kota,
    required this.kecamatan,
    required this.kodePos,
    required this.jalan,
    this.detail = '',
    this.label = 'Rumah',
  });

  /// Seluruh alamat dalam satu kalimat.
  String get lengkap {
    final baris1 = detail.isEmpty ? jalan : '$jalan ($detail)';
    return '$baris1, $kecamatan, $kota, $provinsi, $kodePos';
  }
}

/// Alamat terakhir yang disimpan, supaya tidak perlu diisi ulang.
Alamat? _alamatTersimpan;

const List<String> _daftarProvinsi = [
  'Aceh',
  'Sumatera Utara',
  'Sumatera Barat',
  'Riau',
  'Kepulauan Riau',
  'Jambi',
  'Sumatera Selatan',
  'Kepulauan Bangka Belitung',
  'Bengkulu',
  'Lampung',
  'DKI Jakarta',
  'Banten',
  'Jawa Barat',
  'Jawa Tengah',
  'DI Yogyakarta',
  'Jawa Timur',
  'Bali',
  'Nusa Tenggara Barat',
  'Nusa Tenggara Timur',
  'Kalimantan Barat',
  'Kalimantan Tengah',
  'Kalimantan Selatan',
  'Kalimantan Timur',
  'Kalimantan Utara',
  'Sulawesi Utara',
  'Gorontalo',
  'Sulawesi Tengah',
  'Sulawesi Barat',
  'Sulawesi Selatan',
  'Sulawesi Tenggara',
  'Maluku',
  'Maluku Utara',
  'Papua',
  'Papua Barat',
  'Papua Barat Daya',
  'Papua Selatan',
  'Papua Tengah',
  'Papua Pegunungan',
];

// ---------------------------------------------------------------------
//  DATA VOUCHER
// ---------------------------------------------------------------------

class _Voucher {
  final String kode;
  final String judul;
  final String syarat;
  final int minBelanja;
  final int persen;
  final int maksimal;
  final int potonganTetap;
  final bool gratisOngkir;

  const _Voucher({
    required this.kode,
    required this.judul,
    required this.syarat,
    required this.minBelanja,
    this.persen = 0,
    this.maksimal = 0,
    this.potonganTetap = 0,
    this.gratisOngkir = false,
  });

  /// Besar potongan untuk belanjaan [subtotal] dan ongkir [ongkir].
  int potongan(int subtotal, int ongkir) {
    if (subtotal < minBelanja) return 0;
    if (gratisOngkir) return ongkir < maksimal ? ongkir : maksimal;
    if (persen > 0) {
      final p = subtotal * persen ~/ 100;
      return p < maksimal ? p : maksimal;
    }
    return potonganTetap;
  }
}

const List<_Voucher> _daftarVoucher = [
  _Voucher(
    kode: 'OLEH10',
    judul: 'Diskon 10%',
    syarat: 'Min. belanja Rp 50.000 · maks. potongan Rp 20.000',
    minBelanja: 50000,
    persen: 10,
    maksimal: 20000,
  ),
  _Voucher(
    kode: 'ONGKIRGRATIS',
    judul: 'Gratis Ongkir',
    syarat: 'Min. belanja Rp 100.000 · maks. potongan Rp 20.000',
    minBelanja: 100000,
    gratisOngkir: true,
    maksimal: 20000,
  ),
  _Voucher(
    kode: 'SUMBAR25',
    judul: 'Potongan Rp 25.000',
    syarat: 'Min. belanja Rp 250.000',
    minBelanja: 250000,
    potonganTetap: 25000,
  ),
];

// ---------------------------------------------------------------------
//  DATA PESANAN
// ---------------------------------------------------------------------

enum StatusPesanan { menungguPembayaran, dikemas, dibatalkan }

String _labelStatus(StatusPesanan s) {
  switch (s) {
    case StatusPesanan.menungguPembayaran:
      return 'Menunggu Pembayaran';
    case StatusPesanan.dikemas:
      return 'Sedang Dikemas';
    case StatusPesanan.dibatalkan:
      return 'Dibatalkan';
  }
}

Color _warnaStatus(StatusPesanan s) {
  switch (s) {
    case StatusPesanan.menungguPembayaran:
      return Colors.orange.shade800;
    case StatusPesanan.dikemas:
      return Colors.green.shade700;
    case StatusPesanan.dibatalkan:
      return Colors.black54;
  }
}

class Pesanan {
  final String no;
  final DateTime waktu;
  final List<CartItem> barang;
  final int subtotal;
  final int ongkir;
  final int layanan;
  final int diskon;
  final int total;
  final String metodeBayar;
  final String instruksi;
  final String? noRekening;
  final String kurir;
  final Alamat alamat;
  StatusPesanan status;

  Pesanan({
    required this.no,
    required this.waktu,
    required this.barang,
    required this.subtotal,
    required this.ongkir,
    required this.layanan,
    required this.diskon,
    required this.total,
    required this.metodeBayar,
    required this.instruksi,
    required this.noRekening,
    required this.kurir,
    required this.alamat,
    required this.status,
  });

  /// Batas waktu bayar: 24 jam setelah pesanan dibuat.
  DateTime get batasBayar => waktu.add(const Duration(hours: 24));
  int get jumlahBarang => barang.fold(0, (s, i) => s + i.jumlah);
}

class PesananModel extends ChangeNotifier {
  PesananModel._();
  static final PesananModel instance = PesananModel._();

  final List<Pesanan> _daftar = [];

  List<Pesanan> get daftar => List.unmodifiable(_daftar);

  /// Jumlah pesanan yang masih menunggu pembayaran (untuk badge).
  int get perluBayar =>
      _daftar.where((p) => p.status == StatusPesanan.menungguPembayaran).length;

  void tambah(Pesanan p) {
    _daftar.insert(0, p);
    notifyListeners();
  }

  void ubahStatus(Pesanan p, StatusPesanan s) {
    p.status = s;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------
//  TOMBOL-TOMBOL YANG DIPAKAI HALAMAN LAIN
// ---------------------------------------------------------------------

/// Buka form pilihan ukuran/jumlah. Setelah dipilih, produk masuk keranjang
/// + notifikasi dengan tombol LIHAT (hilang sendiri setelah 3 detik).
Future<void> tambahKeKeranjang(BuildContext context, Product produk) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final pilihan = await tampilkanFormVarian(
    context,
    produk,
    maks: CartModel.maksPerProduk,
  );
  if (pilihan == null) return; // form ditutup tanpa memilih

  final berhasil = CartModel.instance.tambah(
    produk,
    pilihan.varian,
    jumlah: pilihan.jumlah,
  );
  messenger.hideCurrentSnackBar();

  if (!berhasil) {
    messenger.showSnackBar(
      SnackBar(content: Text('Maksimal ${CartModel.maksPerProduk} per produk')),
    );
    return;
  }

  messenger.showSnackBar(
    SnackBar(
      content: Text('${produk.nama} (${pilihan.varian.label}) masuk keranjang'),
      duration: const Duration(seconds: 3),
      // Tanpa ini, notifikasi yang punya tombol tidak hilang sendiri.
      persist: false,
      action: SnackBarAction(
        label: 'LIHAT',
        textColor: const Color(0xFFFFD54F),
        onPressed: () => navigator.push(
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

/// Dialog konfirmasi (hapus barang, batalkan pesanan, dll).
Future<void> _konfirmasiHapus(
  BuildContext context, {
  required String judul,
  required String isi,
  required VoidCallback onHapus,
  String labelYa = 'Hapus',
}) async {
  final ya = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Kembali'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(labelYa),
        ),
      ],
    ),
  );
  if (ya == true) onHapus();
}

/// Hapus satu barang dari keranjang, lalu tawarkan tombol BATAL.
void _hapusDariKeranjang(BuildContext context, CartModel cart, CartItem item) {
  final messenger = ScaffoldMessenger.of(context);
  final posisi = cart.indeksDari(item);
  cart.hapus(item);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          '${item.produk.nama} (${item.varian.label}) dihapus dari keranjang',
        ),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: 'BATAL',
          textColor: const Color(0xFFFFD54F),
          onPressed: () => cart.sisipkan(posisi, item),
        ),
      ),
    );
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
          appBar: AppBar(
            title: Text('Keranjang Saya (${cart.totalItem})'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              // Riwayat pesanan
              ListenableBuilder(
                listenable: PesananModel.instance,
                builder: (context, _) {
                  final n = PesananModel.instance.perluBayar;
                  return IconButton(
                    tooltip: 'Pesanan Saya',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PesananSayaPage(),
                      ),
                    ),
                    icon: Badge(
                      isLabelVisible: n > 0,
                      label: Text('$n'),
                      child: const Icon(Icons.receipt_long_outlined),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
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
    final jumlahJenisDipilih = cart.itemDipilih.length;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      children: [
        // Header toko (centang = pilih semua) + tombol hapus yang dicentang
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
          child: Row(
            children: [
              Checkbox(
                value: cart.semuaDipilih,
                onChanged: (v) => cart.pilihSemua(v ?? false),
              ),
              Icon(Icons.storefront, size: 20, color: tema.colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Toko Oleh-Oleh Sumbar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (jumlahJenisDipilih > 0)
                TextButton.icon(
                  onPressed: () => _konfirmasiHapus(
                    context,
                    judul: 'Hapus produk?',
                    isi:
                        'Hapus $jumlahJenisDipilih produk yang dicentang '
                        'dari keranjang?',
                    onHapus: cart.hapusDipilih,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text('Hapus ($jumlahJenisDipilih)'),
                  style: TextButton.styleFrom(
                    foregroundColor: tema.colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
        for (final item in cart.items) _BarisItem(item: item, cart: cart),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Tekan ikon tong sampah atau geser ke kiri untuk menghapus',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
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
      key: ValueKey(item.kunci),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _hapusDariKeranjang(context, cart, item),
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
            Checkbox(value: item.dipilih, onChanged: (_) => cart.toggle(item)),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.nama,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      // Tombol hapus barang (kalau tidak jadi beli)
                      InkWell(
                        onTap: () => _konfirmasiHapus(
                          context,
                          judul: 'Hapus produk?',
                          isi:
                              'Hapus ${p.nama} (${item.varian.label}) '
                              'dari keranjang?',
                          onHapus: () =>
                              _hapusDariKeranjang(context, cart, item),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Ukuran yang dipilih
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.varian.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatRupiah(item.harga),
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

  void _kurang(BuildContext context) {
    if (item.jumlah > 1) {
      cart.kurang(item);
      return;
    }
    // Jumlah tinggal 1: tanya dulu sebelum dihapus.
    _konfirmasiHapus(
      context,
      judul: 'Hapus produk?',
      isi: 'Hapus ${item.produk.nama} (${item.varian.label}) dari keranjang?',
      onHapus: () => _hapusDariKeranjang(context, cart, item),
    );
  }

  void _tambah(BuildContext context) {
    if (!cart.tambah(item.produk, item.varian)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Maksimal ${CartModel.maksPerProduk} per produk'),
          ),
        );
    }
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
          _TombolStep(icon: Icons.add, onTap: () => _tambah(context)),
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
            'Yuk pilih oleh-oleh khas Sumbar!',
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

/// Pilihan bank untuk Transfer Bank.
const List<String> _daftarBank = ['BRI', 'BNI', 'BSI'];

/// Nomor rekening tujuan transfer.
const String _noRekening = '1234567890';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const int _biayaLayanan = 1000;

  late final List<CartItem> _barang;
  final TextEditingController _catatan = TextEditingController();

  Alamat? _alamat = _alamatTersimpan;
  _Voucher? _voucher;
  int _kurir = 1;
  int _bayar = 0;
  int _bank = 0;
  bool _memproses = false;

  @override
  void initState() {
    super.initState();
    // Salinan barang yang dicentang di keranjang.
    _barang = CartModel.instance.itemDipilih
        .map(
          (i) => CartItem(produk: i.produk, varian: i.varian, jumlah: i.jumlah),
        )
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
  int get _diskon {
    final v = _voucher;
    return v == null ? 0 : v.potongan(_subtotalProduk, _ongkir);
  }

  int get _total => _subtotalProduk + _ongkir + _biayaLayanan - _diskon;

  Future<void> _ubahAlamat() async {
    final hasil = await Navigator.push<Alamat>(
      context,
      MaterialPageRoute(builder: (_) => AlamatFormPage(awal: _alamat)),
    );
    if (hasil == null || !mounted) return;
    _alamatTersimpan = hasil;
    setState(() => _alamat = hasil);
  }

  Future<void> _pilihVoucher() async {
    final kode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih Voucher',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final v in _daftarVoucher)
                    _KartuVoucher(
                      voucher: v,
                      subtotal: _subtotalProduk,
                      terpilih: _voucher?.kode == v.kode,
                      onPilih: () => Navigator.pop(ctx, v.kode),
                    ),
                  if (_voucher != null)
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, ''),
                      child: const Text('Lepas voucher'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (kode == null || !mounted) return;
    setState(() {
      _voucher = kode.isEmpty
          ? null
          : _daftarVoucher.firstWhere((v) => v.kode == kode);
    });
  }

  Future<void> _buatPesanan() async {
    if (_memproses) return;

    final alamat = _alamat;
    if (alamat == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Lengkapi alamat pengiriman dulu ya')),
        );
      return;
    }

    setState(() => _memproses = true);

    // Animasi "memproses pesanan"
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pop(context); // tutup animasi

    final bayar = _daftarBayar[_bayar];
    final transfer = bayar.nama == 'Transfer Bank';
    final cod = bayar.nama.startsWith('COD');
    final metode = transfer
        ? 'Transfer Bank ${_daftarBank[_bank]}'
        : bayar.nama;
    final instruksi = cod
        ? ''
        : transfer
        ? 'Transfer ke rekening ${_daftarBank[_bank]} '
              'a.n. Toko Oleh-Oleh Sumbar'
        : 'Selesaikan pembayaran melalui ${bayar.nama}';

    final pesanan = Pesanan(
      no: 'OSB${DateTime.now().millisecondsSinceEpoch % 100000000}',
      waktu: DateTime.now(),
      barang: _barang,
      subtotal: _subtotalProduk,
      ongkir: _ongkir,
      layanan: _biayaLayanan,
      diskon: _diskon,
      total: _total,
      metodeBayar: metode,
      instruksi: instruksi,
      noRekening: transfer ? _noRekening : null,
      kurir: _daftarKurir[_kurir].nama,
      alamat: alamat,
      status: cod ? StatusPesanan.dikemas : StatusPesanan.menungguPembayaran,
    );

    PesananModel.instance.tambah(pesanan);
    CartModel.instance.hapusDipilih();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => PesananBerhasilPage(pesanan: pesanan)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: tema.colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _kartuAlamat(tema),
          _kartuProduk(tema),
          _kartuKurir(tema),
          _kartuVoucher(tema),
          _kartuBayar(tema),
          _kartuRincian(tema),
        ],
      ),
      bottomNavigationBar: _barBayar(tema),
    );
  }

  // ----- Alamat -----
  Widget _kartuAlamat(ThemeData tema) {
    final a = _alamat;

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
                child: a == null
                    ? Text(
                        'Tambahkan alamat pengiriman',
                        style: TextStyle(
                          color: tema.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Column(
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${a.nama}  |  ${a.telp}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: tema.colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  a.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: tema.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(a.jalan),
                          if (a.detail.isNotEmpty)
                            Text(
                              a.detail,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          Text('${a.kecamatan}, ${a.kota}'),
                          Text('${a.provinsi}, ${a.kodePos}'),
                        ],
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
                'Toko Oleh-Oleh Sumbar',
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
                        Text(
                          'Ukuran: ${b.varian.label}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatRupiah(b.harga),
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

  // ----- Voucher -----
  Widget _kartuVoucher(ThemeData tema) {
    final v = _voucher;

    return _Kartu(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: _pilihVoucher,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                color: tema.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Voucher Toko',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: Text(
                  v == null
                      ? 'Pilih voucher'
                      : '${v.kode}  -${formatRupiah(_diskon)}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: v == null
                        ? Colors.black54
                        : tema.colorScheme.primary,
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
          for (var i = 0; i < _daftarBayar.length; i++) ...[
            _PilihanTile(
              terpilih: _bayar == i,
              onTap: () => setState(() => _bayar = i),
              ikon: _daftarBayar[i].ikon,
              judul: _daftarBayar[i].nama,
            ),
            // Pilihan bank muncul kalau Transfer Bank dipilih
            if (_bayar == i && _daftarBayar[i].nama == 'Transfer Bank')
              _PilihanBank(
                bank: _bank,
                onPilih: (b) => setState(() => _bank = b),
              ),
          ],
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
          if (_diskon > 0)
            _BarisRincian(
              'Diskon Voucher',
              '-${formatRupiah(_diskon)}',
              warna: Colors.green.shade700,
            ),
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
              onPressed: _memproses ? null : _buatPesanan,
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

/// Pilihan bank + nomor rekening (muncul di bawah "Transfer Bank").
class _PilihanBank extends StatelessWidget {
  final int bank;
  final ValueChanged<int> onPilih;

  const _PilihanBank({required this.bank, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(left: 36, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tema.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih bank',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < _daftarBank.length; i++)
                ChoiceChip(
                  label: Text(_daftarBank[i]),
                  selected: bank == i,
                  onSelected: (_) => onPilih(i),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No. Rekening ${_daftarBank[bank]}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const Text(
                      _noRekening,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Salin nomor rekening',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: _noRekening));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Nomor rekening disalin')),
                    );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Satu voucher di daftar pilihan voucher.
class _KartuVoucher extends StatelessWidget {
  final _Voucher voucher;
  final int subtotal;
  final bool terpilih;
  final VoidCallback onPilih;

  const _KartuVoucher({
    required this.voucher,
    required this.subtotal,
    required this.terpilih,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final layak = subtotal >= voucher.minBelanja;
    final kurang = voucher.minBelanja - subtotal;

    return Opacity(
      opacity: layak ? 1 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: terpilih ? tema.colorScheme.primary : Colors.black12,
            width: terpilih ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: layak ? onPilih : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  voucher.gratisOngkir
                      ? Icons.local_shipping_outlined
                      : Icons.discount_outlined,
                  color: tema.colorScheme.primary,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.judul,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        voucher.syarat,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        'Kode: ${voucher.kode}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      if (!layak)
                        Text(
                          'Belanja ${formatRupiah(kurang)} lagi',
                          style: TextStyle(
                            fontSize: 12,
                            color: tema.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
                if (layak)
                  Icon(
                    terpilih
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: terpilih ? tema.colorScheme.primary : Colors.black38,
                  ),
              ],
            ),
          ),
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

// ---------------------------------------------------------------------
//  HALAMAN FORM ALAMAT (gaya Shopee)
// ---------------------------------------------------------------------

class AlamatFormPage extends StatefulWidget {
  final Alamat? awal;

  const AlamatFormPage({super.key, this.awal});

  @override
  State<AlamatFormPage> createState() => _AlamatFormPageState();
}

class _AlamatFormPageState extends State<AlamatFormPage> {
  final _kunci = GlobalKey<FormState>();

  late final TextEditingController _nama = TextEditingController(
    text: widget.awal?.nama,
  );
  late final TextEditingController _telp = TextEditingController(
    text: widget.awal?.telp,
  );
  late final TextEditingController _kota = TextEditingController(
    text: widget.awal?.kota,
  );
  late final TextEditingController _kecamatan = TextEditingController(
    text: widget.awal?.kecamatan,
  );
  late final TextEditingController _kodePos = TextEditingController(
    text: widget.awal?.kodePos,
  );
  late final TextEditingController _jalan = TextEditingController(
    text: widget.awal?.jalan,
  );
  late final TextEditingController _detail = TextEditingController(
    text: widget.awal?.detail,
  );

  late String _provinsi = widget.awal?.provinsi ?? 'Sumatera Barat';
  late String _label = widget.awal?.label ?? 'Rumah';

  @override
  void dispose() {
    _nama.dispose();
    _telp.dispose();
    _kota.dispose();
    _kecamatan.dispose();
    _kodePos.dispose();
    _jalan.dispose();
    _detail.dispose();
    super.dispose();
  }

  String? _wajib(String? v, String nama) =>
      (v == null || v.trim().isEmpty) ? '$nama wajib diisi' : null;

  String? _cekTelp(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Nomor telepon wajib diisi';
    if (!RegExp(r'^[0-9+]{9,15}$').hasMatch(t)) {
      return 'Nomor telepon tidak valid';
    }
    return null;
  }

  String? _cekKodePos(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Kode pos wajib diisi';
    if (!RegExp(r'^[0-9]{5}$').hasMatch(t)) return 'Kode pos harus 5 angka';
    return null;
  }

  Future<void> _pilihProvinsi() async {
    final hasil = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih Provinsi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _daftarProvinsi.length,
                itemBuilder: (_, i) {
                  final p = _daftarProvinsi[i];
                  return ListTile(
                    title: Text(p),
                    trailing: p == _provinsi
                        ? Icon(
                            Icons.check,
                            color: Theme.of(ctx).colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(ctx, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (hasil != null && mounted) setState(() => _provinsi = hasil);
  }

  void _simpan() {
    if (!_kunci.currentState!.validate()) return;
    Navigator.pop(
      context,
      Alamat(
        nama: _nama.text.trim(),
        telp: _telp.text.trim(),
        provinsi: _provinsi,
        kota: _kota.text.trim(),
        kecamatan: _kecamatan.text.trim(),
        kodePos: _kodePos.text.trim(),
        jalan: _jalan.text.trim(),
        detail: _detail.text.trim(),
        label: _label,
      ),
    );
  }

  /// Jarak antar kolom isian.
  Widget _baris(Widget isi) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: isi);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.awal == null ? 'Alamat Baru' : 'Ubah Alamat'),
        backgroundColor: tema.colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _kunci,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // ----- Kontak -----
                _Kartu(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kontak',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _baris(
                        TextFormField(
                          controller: _nama,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => _wajib(v, 'Nama lengkap'),
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      _baris(
                        TextFormField(
                          controller: _telp,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+]'),
                            ),
                            LengthLimitingTextInputFormatter(15),
                          ],
                          validator: _cekTelp,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon',
                            hintText: 'Contoh: 081234567890',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ----- Alamat -----
                _Kartu(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alamat',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _baris(
                        InkWell(
                          onTap: _pilihProvinsi,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Provinsi',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.chevron_right),
                            ),
                            child: Text(_provinsi),
                          ),
                        ),
                      ),
                      _baris(
                        TextFormField(
                          controller: _kota,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => _wajib(v, 'Kota/Kabupaten'),
                          decoration: const InputDecoration(
                            labelText: 'Kota / Kabupaten',
                            hintText: 'Contoh: Kota Padang',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      _baris(
                        TextFormField(
                          controller: _kecamatan,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => _wajib(v, 'Kecamatan'),
                          decoration: const InputDecoration(
                            labelText: 'Kecamatan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      _baris(
                        TextFormField(
                          controller: _kodePos,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          validator: _cekKodePos,
                          decoration: const InputDecoration(
                            labelText: 'Kode Pos',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ----- Detail alamat -----
                _Kartu(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Alamat',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _baris(
                        TextFormField(
                          controller: _jalan,
                          maxLines: 2,
                          validator: (v) => _wajib(v, 'Nama jalan'),
                          decoration: const InputDecoration(
                            labelText: 'Nama Jalan, Gedung, No. Rumah',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      _baris(
                        TextFormField(
                          controller: _detail,
                          decoration: const InputDecoration(
                            labelText: 'Detail Lainnya (opsional)',
                            hintText: 'Contoh: Blok / Unit No., patokan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ----- Penanda -----
                _Kartu(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tandai Sebagai',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final l in const ['Rumah', 'Kantor'])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(l),
                                selected: _label == l,
                                onSelected: (_) => setState(() => _label = l),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _simpan,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Simpan Alamat'),
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
  final Pesanan pesanan;

  const PesananBerhasilPage({super.key, required this.pesanan});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final p = pesanan;

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
                child: ListenableBuilder(
                  listenable: PesananModel.instance,
                  builder: (context, _) {
                    return Column(
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
                          'Terima kasih sudah belanja oleh-oleh khas Sumbar',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),

                        // ----- Petunjuk pembayaran -----
                        if (p.status == StatusPesanan.menungguPembayaran) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFFD54F),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selesaikan pembayaran sebelum',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  _formatTanggal(p.batasBayar),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(p.instruksi),
                                if (p.noRekening != null)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.noRekening!,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Salin nomor rekening',
                                        icon: const Icon(Icons.copy, size: 18),
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(text: p.noRekening!),
                                          );
                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Nomor rekening disalin',
                                                ),
                                              ),
                                            );
                                        },
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total yang harus dibayar: '
                                  '${formatRupiah(p.total)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ----- Ringkasan pesanan -----
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _BarisInfo('No. Pesanan', p.no),
                              _BarisInfo(
                                'Status',
                                _labelStatus(p.status),
                                warna: _warnaStatus(p.status),
                                tebal: true,
                              ),
                              _BarisInfo('Pembayaran', p.metodeBayar),
                              _BarisInfo('Pengiriman', p.kurir),
                              _BarisInfo(
                                'Penerima',
                                '${p.alamat.nama} (${p.alamat.telp})',
                              ),
                              _BarisInfo('Alamat', p.alamat.lengkap),
                              const Divider(height: 24),
                              _BarisInfo(
                                'Subtotal Produk',
                                formatRupiah(p.subtotal),
                              ),
                              _BarisInfo('Ongkir', formatRupiah(p.ongkir)),
                              _BarisInfo(
                                'Biaya Layanan',
                                formatRupiah(p.layanan),
                              ),
                              if (p.diskon > 0)
                                _BarisInfo(
                                  'Diskon Voucher',
                                  '-${formatRupiah(p.diskon)}',
                                  warna: Colors.green.shade700,
                                ),
                              const Divider(height: 24),
                              _BarisInfo(
                                'Total Pembayaran',
                                formatRupiah(p.total),
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
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PesananSayaPage(),
                              ),
                            ),
                            child: const Text('Lihat Pesanan Saya'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.popUntil(context, (r) => r.isFirst),
                            child: const Text('Kembali ke Beranda'),
                          ),
                        ),
                      ],
                    );
                  },
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
//  HALAMAN PESANAN SAYA (riwayat)
// ---------------------------------------------------------------------

class PesananSayaPage extends StatelessWidget {
  const PesananSayaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        backgroundColor: tema.colorScheme.inversePrimary,
      ),
      body: ListenableBuilder(
        listenable: PesananModel.instance,
        builder: (context, _) {
          final daftar = PesananModel.instance.daftar;

          if (daftar.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 90,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada pesanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [for (final p in daftar) _KartuPesanan(pesanan: p)],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KartuPesanan extends StatelessWidget {
  final Pesanan pesanan;

  const _KartuPesanan({required this.pesanan});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final p = pesanan;
    final model = PesananModel.instance;
    final menunggu = p.status == StatusPesanan.menungguPembayaran;

    return _Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, size: 20, color: tema.colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Toko Oleh-Oleh Sumbar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                _labelStatus(p.status),
                style: TextStyle(
                  color: _warnaStatus(p.status),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${p.no} · ${_formatTanggal(p.waktu)}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const Divider(height: 20),
          for (final b in p.barang)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: _Thumbnail(produk: b.produk),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${b.produk.nama} (${b.varian.label})',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${formatRupiah(b.harga)}  x${b.jumlah}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${p.jumlahBarang} produk · Total Pesanan: '
              '${formatRupiah(p.total)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              p.metodeBayar.replaceAll('\n', ' '),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          if (menunggu) ...[
            const SizedBox(height: 6),
            Text(
              'Bayar sebelum ${_formatTanggal(p.batasBayar)}',
              style: TextStyle(fontSize: 12, color: tema.colorScheme.error),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _konfirmasiHapus(
                    context,
                    judul: 'Batalkan pesanan?',
                    isi: 'Pesanan ${p.no} akan dibatalkan.',
                    labelYa: 'Batalkan',
                    onHapus: () =>
                        model.ubahStatus(p, StatusPesanan.dibatalkan),
                  ),
                  child: const Text('Batalkan'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    model.ubahStatus(p, StatusPesanan.dikemas);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Pembayaran diterima (simulasi)'),
                        ),
                      );
                  },
                  child: const Text('Bayar Sekarang'),
                ),
              ],
            ),
          ],
          if (p.status == StatusPesanan.dikemas) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text('Lacak Pesanan'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LacakPesananPage(pesanan: p),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  GAMBAR KECIL PRODUK (dipakai keranjang, checkout, pesanan)
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
