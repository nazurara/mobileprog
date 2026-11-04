import '../models/product.dart';

const List<String> daftarKategori = [
  'Semua',
  'Keripik & Kerupuk',
  'Lauk Kemasan',
  'Kue & Camilan',
  'Minuman',
  'Kerajinan',
];

const List<Product> daftarProduk = [
  Product(
    id: 1,
    nama: 'Keripik Sanjai Balado',
    harga: 35000,
    kategori: 'Keripik & Kerupuk',
    deskripsi: 'Keripik singkong tipis khas Bukittinggi dengan bumbu balado pedas manis. Renyah dan cocok jadi oleh-oleh. Berat bersih 250 gram.',
  ),
  Product(
    id: 2,
    nama: 'Keripik Sanjai Original',
    harga: 30000,
    kategori: 'Keripik & Kerupuk',
    deskripsi: 'Keripik singkong gurih asin tanpa bumbu pedas, cocok untuk semua usia. Berat bersih 250 gram.',
  ),
  Product(
    id: 3,
    nama: 'Kerupuk Jangek',
    harga: 25000,
    kategori: 'Keripik & Kerupuk',
    deskripsi: 'Kerupuk kulit sapi khas Minang yang gurih dan renyah, enak dimakan bersama sate atau soto. Berat bersih 200 gram.',
  ),
  Product(
    id: 4,
    nama: 'Rendang Daging Kemasan',
    harga: 85000,
    kategori: 'Lauk Kemasan',
    deskripsi: 'Rendang daging sapi dimasak berjam-jam dengan santan dan rempah pilihan. Tahan lama dan praktis dibawa bepergian. Berat bersih 250 gram.',
  ),
  Product(
    id: 5,
    nama: 'Dendeng Batokok',
    harga: 70000,
    kategori: 'Lauk Kemasan',
    deskripsi: 'Dendeng sapi yang dipukul tipis lalu digoreng, disajikan dengan cabai hijau. Gurih, pedas, dan wangi. Berat bersih 200 gram.',
  ),
  Product(
    id: 6,
    nama: 'Bolu Kemojo',
    harga: 40000,
    kategori: 'Kue & Camilan',
    deskripsi: 'Kue bolu manis berbentuk khas dengan tekstur lembut, dibuat dari tepung, telur, dan gula. Isi 12 buah.',
  ),
  Product(
    id: 7,
    nama: 'Karak Kaliang',
    harga: 28000,
    kategori: 'Kue & Camilan',
    deskripsi: 'Camilan renyah berbentuk melingkar dengan rasa gurih dan sedikit pedas. Teman minum teh yang pas. Berat bersih 200 gram.',
  ),
  Product(
    id: 8,
    nama: 'Kopi Kawa Daun',
    harga: 45000,
    kategori: 'Minuman',
    deskripsi: 'Teh khas Minang dari seduhan daun kopi kering yang diberi rempah. Aroma hangat dan menyegarkan. Isi 100 gram.',
  ),
  Product(
    id: 9,
    nama: 'Songket Minang (Selendang)',
    harga: 250000,
    kategori: 'Kerajinan',
    deskripsi: 'Selendang songket tenun tangan khas Sumatera Barat dengan motif tradisional. Cocok untuk hadiah dan acara adat.',
  ),
  Product(
    id: 10,
    nama: 'Gantungan Kunci Rumah Gadang',
    harga: 15000,
    kategori: 'Kerajinan',
    deskripsi: 'Souvenir mini berbentuk Rumah Gadang dari bahan kayu yang dicat rapi. Ringan dan mudah dibawa pulang.',
  ),
];
