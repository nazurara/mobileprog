import 'package:flutter/material.dart';

import '../models/product.dart';

// =====================================================================
//  VARIAN PRODUK (ukuran + harga) + FORM PILIHAN
//
//  Mau ubah ukuran atau harga? Edit saja daftar _varianProduk di bawah.
//  Kuncinya adalah ID produk (sama dengan id di dummy_data.dart).
//  Produk yang belum terdaftar otomatis dapat 1 pilihan "Standar"
//  dengan harga aslinya.
// =====================================================================

/// Satu pilihan ukuran lengkap dengan harganya.
class Varian {
  final String label;
  final int harga;

  const Varian(this.label, this.harga);
}

/// Hasil dari form: varian yang dipilih + jumlahnya.
class PilihanVarian {
  final Varian varian;
  final int jumlah;

  const PilihanVarian(this.varian, this.jumlah);
}

const Map<int, List<Varian>> _varianProduk = {
  // 1 - Keripik Sanjai Balado
  1: [
    Varian('250 gram', 35000),
    Varian('500 gram', 67000),
    Varian('1 kg', 130000),
  ],
  // 2 - Keripik Sanjai Original
  2: [
    Varian('250 gram', 30000),
    Varian('500 gram', 57000),
    Varian('1 kg', 110000),
  ],
  // 3 - Kerupuk Jangek
  3: [
    Varian('200 gram', 25000),
    Varian('500 gram', 59000),
    Varian('1 kg', 115000),
  ],
  // 4 - Rendang Daging Kemasan
  4: [
    Varian('250 gram', 85000),
    Varian('500 gram', 165000),
    Varian('1 kg', 320000),
  ],
  // 5 - Dendeng Batokok
  5: [
    Varian('200 gram', 70000),
    Varian('500 gram', 170000),
    Varian('1 kg', 330000),
  ],
  // 6 - Bolu Kemojo
  6: [Varian('Isi 6', 22000), Varian('Isi 12', 40000), Varian('Isi 24', 76000)],
  // 7 - Karak Kaliang
  7: [
    Varian('200 gram', 28000),
    Varian('500 gram', 66000),
    Varian('1 kg', 128000),
  ],
  // 8 - Kopi Kawa Daun
  8: [
    Varian('100 gram', 45000),
    Varian('250 gram', 105000),
    Varian('500 gram', 200000),
  ],
  // 9 - Songket Minang (Selendang)
  9: [
    Varian('Motif Sederhana', 250000),
    Varian('Motif Sedang', 350000),
    Varian('Motif Lengkap (Benang Emas)', 500000),
  ],
  // 10 - Gantungan Kunci Rumah Gadang
  10: [Varian('Satuan', 15000), Varian('Isi 3', 42000), Varian('Isi 6', 80000)],
  // 11 - Kerbau Khas Minang
  11: [
    Varian('Kerbau Muda', 35000000),
    Varian('Kerbau Dewasa', 45000000),
    Varian('Kerbau Jantan Besar', 65000000),
  ],
};

/// Daftar ukuran + harga untuk satu produk.
List<Varian> daftarVarian(Product p) {
  return _varianProduk[p.id] ?? [Varian('Standar', p.harga)];
}

String _rp(int angka) {
  final teks = angka.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => '.',
  );
  return 'Rp $teks';
}

/// Membuka form pilihan ukuran. Hasilnya null kalau ditutup tanpa memilih.
Future<PilihanVarian?> tampilkanFormVarian(
  BuildContext context,
  Product produk, {
  int maks = 20,
}) {
  return showModalBottomSheet<PilihanVarian>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _FormVarian(produk: produk, maks: maks),
  );
}

class _FormVarian extends StatefulWidget {
  final Product produk;
  final int maks;

  const _FormVarian({required this.produk, required this.maks});

  @override
  State<_FormVarian> createState() => _FormVarianState();
}

class _FormVarianState extends State<_FormVarian> {
  late final List<Varian> _daftar = daftarVarian(widget.produk);
  late int _terpilih = () {
    final i = _daftar.indexWhere((v) => v.harga == widget.produk.harga);
    return i == -1 ? 0 : i;
  }();
  int _jumlah = 1;

  Varian get _varian => _daftar[_terpilih];
  int get _total => _varian.harga * _jumlah;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final p = widget.produk;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- Ringkasan produk -----
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: p.gambar.isEmpty
                        ? _placeholder(tema)
                        : Image.asset(
                            p.gambar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder(tema),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _rp(_varian.harga),
                        style: tema.textTheme.titleLarge?.copyWith(
                          color: tema.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            // ----- Pilihan ukuran -----
            const Text(
              'Pilih Ukuran',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _daftar.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _terpilih = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _terpilih == i
                          ? tema.colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            )
                          : null,
                      border: Border.all(
                        color: _terpilih == i
                            ? tema.colorScheme.primary
                            : Colors.black12,
                        width: _terpilih == i ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _terpilih == i
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: _terpilih == i
                              ? tema.colorScheme.primary
                              : Colors.black38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _daftar[i].label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          _rp(_daftar[i].harga),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // ----- Jumlah -----
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Jumlah',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton.outlined(
                  onPressed: _jumlah > 1
                      ? () => setState(() => _jumlah--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '$_jumlah',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: _jumlah < widget.maks
                      ? () => setState(() => _jumlah++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ----- Tombol -----
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(context, PilihanVarian(_varian, _jumlah)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: Text('Masukkan Keranjang · ${_rp(_total)}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData tema) {
    return Container(
      color: tema.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(widget.produk.ikon, size: 30),
    );
  }
}
