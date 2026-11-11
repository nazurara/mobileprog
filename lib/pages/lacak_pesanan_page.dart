import 'package:flutter/material.dart';

import 'keranjang_page.dart';

// =====================================================================
//  TRACKING PESANAN (file terpisah, tidak mengubah keranjang_page.dart)
//  Tahap: Dikemas -> Dikirim -> Tiba. Status disimpan di TrackingModel.
//  Belum ada server/kurir asli, jadi pergerakan paket disimulasikan
//  lewat tombol di halaman lacak.
// =====================================================================

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

/// Menyimpan tahap tracking tiap pesanan (kunci: nomor pesanan).
class TrackingModel extends ChangeNotifier {
  TrackingModel._();
  static final TrackingModel instance = TrackingModel._();

  /// Tahap: 0 = dikemas, 1 = dikirim, 2 = tiba.
  final Map<String, int> _tahap = {};
  final Map<String, Map<int, DateTime>> _waktu = {};

  /// Dipanggil saat halaman lacak dibuka. Aman dipanggil berkali-kali.
  void mulai(Pesanan p) {
    _tahap.putIfAbsent(p.no, () => 0);
    _waktu.putIfAbsent(p.no, () => {0: DateTime.now()});
  }

  int tahap(Pesanan p) => _tahap[p.no] ?? 0;
  DateTime? waktu(Pesanan p, int tahap) => _waktu[p.no]?[tahap];

  bool bisaMaju(Pesanan p) => tahap(p) < 2;

  void maju(Pesanan p) {
    if (!bisaMaju(p)) return;
    final baru = tahap(p) + 1;
    _tahap[p.no] = baru;
    _waktu[p.no]![baru] = DateTime.now();
    notifyListeners();
  }
}

class LacakPesananPage extends StatefulWidget {
  final Pesanan pesanan;

  const LacakPesananPage({super.key, required this.pesanan});

  @override
  State<LacakPesananPage> createState() => _LacakPesananPageState();
}

class _LacakPesananPageState extends State<LacakPesananPage> {
  @override
  void initState() {
    super.initState();
    TrackingModel.instance.mulai(widget.pesanan);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final p = widget.pesanan;
    final model = TrackingModel.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Lacak Pesanan'),
        backgroundColor: tema.colorScheme.inversePrimary,
      ),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          final tahap = model.tahap(p);
          final adaResi = tahap >= 1;
          final resi = 'LPK${p.no.replaceAll(RegExp(r'[^0-9]'), '')}';
          final labelStatus = [
            'Sedang Dikemas',
            'Sedang Dikirim',
            'Pesanan Tiba',
          ][tahap];

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
          // Langkah 0 (dibuat) selalu selesai, jadi tahap tracking + 1.
          final posisi = tahap + 1;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // ----- Info pesanan -----
                  _Kotak(
                    child: Column(
                      children: [
                        _Info('No. Pesanan', p.no),
                        _Info('No. Resi', adaResi ? resi : 'Belum tersedia'),
                        _Info('Kurir', p.kurir),
                        _Info(
                          'Status',
                          labelStatus,
                          warna: tahap == 2
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                          tebal: true,
                        ),
                      ],
                    ),
                  ),

                  // ----- Garis waktu -----
                  _Kotak(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Perjalanan Pesanan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        for (var i = 0; i < langkah.length; i++)
                          _BarisLangkah(
                            langkah: langkah[i],
                            selesai: i <= posisi,
                            aktif: i == posisi,
                            terakhir: i == langkah.length - 1,
                          ),
                      ],
                    ),
                  ),

                  // ----- Alamat tujuan -----
                  _Kotak(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: tema.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.alamat.nama}  |  ${p.alamat.telp}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(p.alamat.lengkap),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ----- Tombol demo -----
                  if (model.bisaMaju(p))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: FilledButton.icon(
                        onPressed: () => model.maju(p),
                        icon: const Icon(Icons.fast_forward),
                        label: Text(
                          tahap == 0
                              ? 'Simulasi: kirim paket'
                              : 'Simulasi: paket tiba',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Langkah {
  final String judul;
  final String ket;
  final IconData ikon;
  final DateTime? waktu;

  const _Langkah(this.judul, this.ket, this.ikon, this.waktu);
}

/// Kotak putih tiap bagian.
class _Kotak extends StatelessWidget {
  final Widget child;

  const _Kotak({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: Colors.white,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

/// Baris "label ........ nilai".
class _Info extends StatelessWidget {
  final String label;
  final String nilai;
  final bool tebal;
  final Color? warna;

  const _Info(this.label, this.nilai, {this.tebal = false, this.warna});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

/// Satu baris garis waktu: lingkaran ikon + garis + teks.
class _BarisLangkah extends StatelessWidget {
  final _Langkah langkah;
  final bool selesai;
  final bool aktif;
  final bool terakhir;

  const _BarisLangkah({
    required this.langkah,
    required this.selesai,
    required this.aktif,
    required this.terakhir,
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: warna,
                  child: Icon(langkah.ikon, size: 18, color: Colors.white),
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
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: terakhir ? 0 : 24),
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
