import 'package:flutter/material.dart';

import 'keranjang_page.dart';
import 'lacak_pesanan_page.dart';

// =====================================================================
//  HALAMAN PESANAN SAYA (riwayat) - tampilan baru.
//  Status ikut berjalan sesuai tracking (Dikemas -> Dikirim -> Tiba).
// =====================================================================

String _formatTgl(DateTime d) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${d.day} ${bulan[d.month - 1]} ${d.year}, ${dua(d.hour)}:${dua(d.minute)}';
}

/// Label, warna, dan kelompok filter untuk satu status.
class _InfoStatus {
  final String label;
  final Color warna;
  final IconData ikon;

  /// 1 menunggu, 2 dikemas, 3 dikirim, 4 tiba, 5 dibatalkan.
  final int kelompok;

  const _InfoStatus(this.label, this.warna, this.ikon, this.kelompok);
}

_InfoStatus _statusDari(Pesanan p) {
  switch (p.status) {
    case StatusPesanan.menungguPembayaran:
      return _InfoStatus(
        'Menunggu Pembayaran',
        Colors.orange.shade800,
        Icons.schedule,
        1,
      );
    case StatusPesanan.dibatalkan:
      return _InfoStatus(
        'Dibatalkan',
        Colors.black54,
        Icons.cancel_outlined,
        5,
      );
    case StatusPesanan.dikemas:
      switch (TrackingModel.instance.tahap(p)) {
        case 1:
          return _InfoStatus(
            'Sedang Dikirim',
            Colors.purple.shade600,
            Icons.local_shipping_outlined,
            3,
          );
        case 2:
          return _InfoStatus(
            'Pesanan Tiba',
            Colors.green.shade700,
            Icons.check_circle_outline,
            4,
          );
        default:
          return _InfoStatus(
            'Sedang Dikemas',
            Colors.blue.shade700,
            Icons.inventory_2_outlined,
            2,
          );
      }
  }
}

const List<String> _daftarFilter = [
  'Semua',
  'Menunggu',
  'Dikemas',
  'Dikirim',
  'Tiba',
  'Dibatalkan',
];

// ---------------------------------------------------------------------
//  HALAMAN
// ---------------------------------------------------------------------

class PesananSayaPage extends StatefulWidget {
  const PesananSayaPage({super.key});

  @override
  State<PesananSayaPage> createState() => _PesananSayaPageState();
}

class _PesananSayaPageState extends State<PesananSayaPage> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Di Chrome, bagian luar kolom ini abu-abu supaya terlihat seperti HP.
      backgroundColor: const Color(0xFFE9E2DC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Material(
            color: const Color(0xFFF7F2EE),
            child: ListenableBuilder(
              listenable: Listenable.merge([
                PesananModel.instance,
                TrackingModel.instance,
              ]),
              builder: (context, _) {
                final semua = PesananModel.instance.daftar;

                // Pesanan yang sudah dikemas otomatis mulai dilacak,
                // supaya statusnya di sini ikut berjalan.
                for (final p in semua) {
                  if (p.status == StatusPesanan.dikemas) {
                    TrackingModel.instance.mulai(p);
                  }
                }

                final tampil = semua
                    .where(
                      (p) => _filter == 0 || _statusDari(p).kelompok == _filter,
                    )
                    .toList();

                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _Header(jumlah: semua.length),
                          _filterChips(),
                          if (tampil.isEmpty)
                            _kosong(semua.isEmpty)
                          else
                            ...tampil.map((p) => _KartuRiwayat(pesanan: p)),
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

  Widget _filterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          for (var i = 0; i < _daftarFilter.length; i++)
            ChoiceChip(
              label: Text(_daftarFilter[i]),
              selected: _filter == i,
              onSelected: (_) => setState(() => _filter = i),
            ),
        ],
      ),
    );
  }

  Widget _kosong(bool belumAdaPesanan) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 72, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            belumAdaPesanan
                ? 'Belum ada pesanan'
                : 'Tidak ada pesanan di kategori ini',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            belumAdaPesanan
                ? 'Yuk belanja oleh-oleh khas Sumbar!'
                : 'Coba pilih filter lain',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _barBawah() {
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
        child: FilledButton.icon(
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Kembali ke Beranda'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  HEADER
// ---------------------------------------------------------------------

class _Header extends StatelessWidget {
  final int jumlah;

  const _Header({required this.jumlah});

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
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Riwayat Pesanan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                jumlah == 0 ? 'Belum ada pesanan' : '$jumlah pesanan',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  KARTU PESANAN
// ---------------------------------------------------------------------

class _KartuRiwayat extends StatelessWidget {
  final Pesanan pesanan;

  const _KartuRiwayat({required this.pesanan});

  Future<void> _konfirmasiBatal(BuildContext context) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: Text('Pesanan ${pesanan.no} akan dibatalkan.'),
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
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (ya == true) {
      PesananModel.instance.ubahStatus(pesanan, StatusPesanan.dibatalkan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final p = pesanan;
    final s = _statusDari(p);
    final utama = p.barang.first;
    final sisa = p.barang.length - 1;
    final menunggu = p.status == StatusPesanan.menungguPembayaran;
    final dikemas = p.status == StatusPesanan.dikemas;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
        children: [
          // ----- Pita status -----
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: s.warna.withValues(alpha: 0.09),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(s.ikon, size: 18, color: s.warna),
                const SizedBox(width: 8),
                Text(
                  s.label,
                  style: TextStyle(
                    color: s.warna,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTgl(p.waktu),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No. ${p.no}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 12),

                // ----- Produk utama -----
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: _Gambar(
                          path: utama.produk.gambar,
                          ikon: utama.produk.ikon,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            utama.produk.nama,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${utama.varian.label}  ·  x${utama.jumlah}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          if (sisa > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '+ $sisa produk lainnya',
                              style: TextStyle(
                                fontSize: 12,
                                color: tema.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ----- Total -----
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
                const SizedBox(height: 2),
                Text(
                  p.metodeBayar.replaceAll('\n', ' '),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),

                // ----- Tombol aksi -----
                if (menunggu) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Bayar sebelum ${_formatTgl(p.batasBayar)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: tema.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _konfirmasiBatal(context),
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Batalkan'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          PesananModel.instance.ubahStatus(
                            p,
                            StatusPesanan.dikemas,
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pembayaran diterima (simulasi)',
                                ),
                              ),
                            );
                        },
                        style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Bayar Sekarang'),
                      ),
                    ],
                  ),
                ],
                if (dikemas) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LacakPesananPage(pesanan: p),
                        ),
                      ),
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: const Text('Lacak Pesanan'),
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ],
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
      child: Icon(ikon, size: 28),
    );

    if (path.isEmpty) return placeholder;

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}