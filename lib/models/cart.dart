import 'package:flutter/foundation.dart';
 
import 'product.dart';
 
/// Contoh: 35000 -> "Rp 35.000"
String formatRupiah(int angka) {
  final teks = angka.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => '.',
      );
  return 'Rp $teks';
}
 
/// Satu baris di keranjang: produk + jumlahnya.
class CartItem {
  final Product produk;
  int jumlah;
 
  CartItem({required this.produk, this.jumlah = 1});
 
  int get subtotal => produk.harga * jumlah;
}
 
/// State keranjang belanja (singleton, tanpa package tambahan).
/// Pakai lewat `CartModel.instance`, dan dengarkan perubahannya dengan
/// `ListenableBuilder(listenable: CartModel.instance, ...)`.
class CartModel extends ChangeNotifier {
  CartModel._();
  static final CartModel instance = CartModel._();
 
  final List<CartItem> _items = [];
 
  List<CartItem> get items => List.unmodifiable(_items);
  bool get kosong => _items.isEmpty;
 
  /// Total jumlah barang (dipakai untuk badge di ikon keranjang).
  int get totalItem => _items.fold(0, (sum, i) => sum + i.jumlah);
 
  /// Total harga semua barang.
  int get totalHarga => _items.fold(0, (sum, i) => sum + i.subtotal);
 
  int _cari(Product p) => _items.indexWhere((i) => i.produk.id == p.id);
 
  void tambah(Product p) {
    final idx = _cari(p);
    if (idx == -1) {
      _items.add(CartItem(produk: p));
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
    } else {
      _items.removeAt(idx);
    }
    notifyListeners();
  }
 
  void hapus(Product p) {
    _items.removeWhere((i) => i.produk.id == p.id);
    notifyListeners();
  }
 
  void kosongkan() {
    _items.clear();
    notifyListeners();
  }
}
 