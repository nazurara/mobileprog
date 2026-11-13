import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'keranjang_page.dart';

// =====================================================================
//  TRACKING PESANAN OTOMATIS (file terpisah dari keranjang_page.dart)
//  Tahap: Dikemas -> Dikirim -> Tiba, naik sendiri berdasarkan timer.
//  Belum ada server/kurir asli, jadi pergerakan paket disimulasikan.
//  Mau lebih cepat/lambat? Ubah dua angka di bawah ini.
// =====================================================================

/// Lama dari "Dikemas" sampai "Dikirim".
const Duration _jedaKemas = Duration(minutes: 2);

/// Lama dari "Dikirim" sampai "Tiba".
const Duration _jedaKirim = Duration(minutes: 5);

const Map<String, String> _estimasi = {
  'Hemat': '5-7 hari',
  'Reguler': '3-4 hari',
  'Kilat': '1-2 hari',
};

String _tgl(DateTime d) {
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
//  MODEL TRACKING
// ---------------------------------------------------------------------

/// Menyimpan tahap tracking tiap pesanan (kunci: nomor pesanan).
/// Tahap: 0 = dikemas, 1 = dikirim, 2 = tiba.
class TrackingModel extends ChangeNotifier {
  TrackingModel._();
  static final TrackingModel instance = TrackingModel._();

  final Map<String, int> _tahap = {};
  final Map<String, Map<int, DateTime>> _waktu = {};
  final Map<String, Timer> _timer = {};

  /// Dipanggil saat halaman lacak dibuka. Aman dipanggil berkali-kali.
  void mulai(Pesanan p) {
    if (_tahap.containsKey(p.no)) return;
    _tahap[p.no] = 0;
    _waktu[p.no] = {0: DateTime.now()};
    _jadwalkan(p);
  }

  void _jadwalkan(Pesanan p) {
    final sekarang = _tahap[p.no] ?? 0;
    if (sekarang >= 2) return;
    final jeda = sekarang == 0 ? _jedaKemas : _jedaKirim;

    _timer[p.no] = Timer(jeda, () {
      final baru = (_tahap[p.no] ?? 0) + 1;
      _tahap[p.no] = baru;
      _waktu[p.no]![baru] = DateTime.now();
      notifyListeners();
      _jadwalkan(p);
    });
  }

  int tahap(Pesanan p) => _tahap[p.no] ?? 0;
  DateTime? waktu(Pesanan p, int tahap) => _waktu[p.no]?[tahap];
}

// ---------------------------------------------------------------------
//  HALAMAN LACAK PESANAN
// ---------------------------------------------------------------------

class LacakPesananPage extends StatefulWidget {
  final Pesanan pesanan;

  const LacakPesananPage({super.key, required this.pesanan});

  @override
  State<LacakPesananPage> createState() => _LacakPesananPageState();
}

class _LacakPesananPageState extends State<LacakPesananPage>
    with SingleTickerProviderStateMixin {
  /// Animasi denyut untuk titik tahap yang sedang berjalan.
  late final AnimationController _denyut = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    TrackingModel.instance.mulai(widget.pesanan);
  }

  @override
  void dispose() {
    _denyut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pesanan;
    final model = TrackingModel.instance;

    return Scaffold(
      // Di Chrome, bagian luar kolom ini abu-abu supaya terlihat seperti HP.
      backgroundColor: const Color(0xFFE9E2DC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Material(
            color: const Color(0xFFF7F2EE),
            child: ListenableBuilder(
              listenable: model,
              builder: (context, _) {
                final tahap = model.tahap(p);
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _Header(pesanan: p, tahap: tahap, denyut: _denyut),
                          _kartuPengiriman(p, tahap),
                          _kartuPerjalanan(p, model, tahap),
                          _kartuAlamat(p),
                          _kartuProduk(p),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    _barBawah(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ----- Info pengiriman -----
  Widget _kartuPengiriman(Pesanan p, int tahap) {
    final adaResi = tahap >= 1;
    final resi = 'LPK${p.no.replaceAll(RegExp(r'[^0-9]'), '')}';

    return _Kartu(
      judul: 'Info Pengiriman',
      ikon: Icons.local_shipping_outlined,
      child: Column(
        children: [
          _Info(
            'No. Resi',
            adaResi ? resi : 'Belum tersedia',
            aksi: adaResi
                ? InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: resi));
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('No. resi disalin')),
                        );
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.copy, size: 16),
                    ),
                  )
                : null,
          ),
          _Info('No. Pesanan', p.no),
          _Info('Kurir', p.kurir),
          _Info('Estimasi', _estimasi[p.kurir] ?? '-'),
        ],
      ),
    );
  }

  // ----- Garis waktu -----
  Widget _kartuPerjalanan(Pesanan p, TrackingModel model, int tahap) {
    final langkah = <_Langkah>[
      _Langkah(
        'Pesanan Dibuat',
        'Pesanan kamu sudah kami terima',
        Icons.receipt_long_outlined,
        p.waktu,
      ),
      _Langkah(
        'Dikemas',
        'Oleh-oleh sedang dikemas oleh penjual',
        Icons.inventory_2_outlined,
        model.waktu(p, 0),
      ),
      _Langkah(
        'Dikirim',
        'Paket diserahkan ke kurir ${p.kurir}',
        Icons.local_shipping_outlined,
        model.waktu(p, 1),
      ),
      _Langkah(
        'Tiba di Tujuan',
        'Paket sudah sampai di ${p.alamat.kota}',
        Icons.home_outlined,
        model.waktu(p, 2),
      ),
    ];
    // Langkah 0 (dibuat) selalu selesai, jadi posisi = tahap + 1.
    final posisi = tahap + 1;

    return _Kartu(
      judul: 'Perjalanan Pesanan',
      ikon: Icons.route_outlined,
      child: Column(
        children: [
          for (var i = 0; i < langkah.length; i++)
            _BarisLangkah(
              langkah: langkah[i],
              selesai: i <= posisi,
              aktif: i == posisi && tahap < 2,
              terakhir: i == langkah.length - 1,
              denyut: _denyut,
            ),
        ],
      ),
    );
  }

  // ----- Alamat -----
  Widget _kartuAlamat(Pesanan p) {
    final a = p.alamat;
    return _Kartu(
      judul: 'Alamat Tujuan',
      ikon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${a.nama}  |  ${a.telp}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            a.lengkap,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ----- Produk -----
  Widget _kartuProduk(Pesanan p) {
    final tema = Theme.of(context);

    return _Kartu(
      judul: 'Produk Dipesan',
      ikon: Icons.shopping_bag_outlined,
      child: Column(
        children: [
          for (final b in p.barang)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: _Gambar(
                        path: b.produk.gambar,
                        ikon: b.produk.ikon,
                      ),
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          b.varian.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
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
          const Divider(height: 8),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (${p.jumlahBarang} produk)',
                style: const TextStyle(color: Colors.black54),
              ),
              Text(
                formatRupiah(p.total),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: tema.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              p.metodeBayar.replaceAll('\n', ' '),
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  // ----- Tombol bawah: ke riwayat + ke beranda -----
  Widget _barBawah() {
    const gayaTeks = TextStyle(fontSize: 15, fontWeight: FontWeight.bold);

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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Riwayat'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  textStyle: gayaTeks,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Beranda'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  textStyle: gayaTeks,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  HEADER (ikon status besar + bar progres)
// ---------------------------------------------------------------------

class _Header extends StatelessWidget {
  final Pesanan pesanan;
  final int tahap;
  final Animation<double> denyut;

  const _Header({
    required this.pesanan,
    required this.tahap,
    required this.denyut,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final warna = tema.colorScheme.primary;

    const judul = [
      'Pesanan Sedang Dikemas',
      'Pesanan Dalam Perjalanan',
      'Pesanan Telah Tiba',
    ];
    final subjudul = [
      'Penjual sedang menyiapkan oleh-olehmu',
      'Kurir ${pesanan.kurir} menuju alamatmu',
      'Selamat menikmati oleh-oleh khas Minang!',
    ];
    const ikon = [
      Icons.inventory_2_outlined,
      Icons.local_shipping_outlined,
      Icons.check_circle_outline,
    ];

    return Container(
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
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
          child: Column(
            children: [
              // Judul (tanpa tombol kembali)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Lacak Pesanan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Ikon status besar
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Container(
                  key: ValueKey(tahap),
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: Icon(ikon[tahap], size: 44, color: Colors.white),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  judul[tahap],
                  key: ValueKey('j$tahap'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subjudul[tahap],
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 22),

              // Bar progres
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _BarProgres(tahap: tahap, denyut: denyut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiga titik (Dikemas - Dikirim - Tiba) dihubungkan garis yang terisi.
class _BarProgres extends StatelessWidget {
  final int tahap;
  final Animation<double> denyut;

  const _BarProgres({required this.tahap, required this.denyut});

  @override
  Widget build(BuildContext context) {
    const label = ['Dikemas', 'Dikirim', 'Tiba'];
    const ikon = [
      Icons.inventory_2_outlined,
      Icons.local_shipping_outlined,
      Icons.home_outlined,
    ];
    final warna = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, cons) {
        const lebarNode = 64.0;
        final panjang = cons.maxWidth - lebarNode;

        return SizedBox(
          height: 74,
          child: Stack(
            children: [
              // Garis dasar
              Positioned(
                left: lebarNode / 2,
                right: lebarNode / 2,
                top: 18,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Garis terisi
              Positioned(
                left: lebarNode / 2,
                top: 18,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  width: panjang * tahap / 2,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Titik-titik
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 3; i++)
                    SizedBox(
                      width: lebarNode,
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: denyut,
                            builder: (context, _) {
                              final selesai = i <= tahap;
                              final aktif = i == tahap && tahap < 2;
                              return Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selesai
                                      ? Colors.white
                                      : Colors.white24,
                                  boxShadow: aktif
                                      ? [
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.5 * denyut.value,
                                            ),
                                            blurRadius: 4 + 14 * denyut.value,
                                            spreadRadius: 3 * denyut.value,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  selesai && !aktif ? Icons.check : ikon[i],
                                  size: 20,
                                  color: selesai ? warna : Colors.white60,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: i <= tahap
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: i <= tahap ? Colors.white : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
//  KOMPONEN KECIL
// ---------------------------------------------------------------------

class _Langkah {
  final String judul;
  final String ket;
  final IconData ikon;
  final DateTime? waktu;

  const _Langkah(this.judul, this.ket, this.ikon, this.waktu);
}

/// Kartu putih membulat dengan judul dan ikon.
class _Kartu extends StatelessWidget {
  final String judul;
  final IconData ikon;
  final Widget child;

  const _Kartu({required this.judul, required this.ikon, required this.child});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 20, color: tema.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Baris "label ........ nilai".
class _Info extends StatelessWidget {
  final String label;
  final String nilai;
  final Widget? aksi;

  const _Info(this.label, this.nilai, {this.aksi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    nilai,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ?aksi,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu baris garis waktu: lingkaran ikon + garis + teks.
class _BarisLangkah extends StatelessWidget {
  final _Langkah langkah;
  final bool selesai;
  final bool aktif;
  final bool terakhir;
  final Animation<double> denyut;

  const _BarisLangkah({
    required this.langkah,
    required this.selesai,
    required this.aktif,
    required this.terakhir,
    required this.denyut,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final warna = selesai ? tema.colorScheme.primary : Colors.black26;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: denyut,
                  builder: (context, _) {
                    return Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: warna,
                        boxShadow: aktif
                            ? [
                                BoxShadow(
                                  color: warna.withValues(
                                    alpha: 0.45 * denyut.value,
                                  ),
                                  blurRadius: 4 + 10 * denyut.value,
                                  spreadRadius: 2 * denyut.value,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(langkah.ikon, size: 18, color: Colors.white),
                    );
                  },
                ),
                if (!terakhir)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: selesai && !aktif
                          ? tema.colorScheme.primary
                          : Colors.black12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: terakhir ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    langkah.judul,
                    style: TextStyle(
                      fontWeight: selesai ? FontWeight.bold : FontWeight.w500,
                      color: selesai ? null : Colors.black45,
                    ),
                  ),
                  Text(
                    langkah.ket,
                    style: TextStyle(
                      fontSize: 12,
                      color: selesai ? Colors.black54 : Colors.black38,
                    ),
                  ),
                  if (langkah.waktu != null)
                    Text(
                      _tgl(langkah.waktu!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gambar produk kecil; kalau tidak ada, tampil ikon kategori.
class _Gambar extends StatelessWidget {
  final String path;
  final IconData ikon;

  const _Gambar({required this.path, required this.ikon});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(ikon, size: 26),
    );

    if (path.isEmpty) return placeholder;

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}
