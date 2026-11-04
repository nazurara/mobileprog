import 'package:flutter_test/flutter_test.dart';
import 'package:mobileprog/main.dart';

void main() {
  testWidgets('Beranda LapakKu menampilkan judul dan produk', (tester) async {
    await tester.pumpWidget(const LapakKuApp());

    expect(find.text('LapakKu'), findsOneWidget);
    expect(find.text('Keripik Sanjai Balado'), findsOneWidget);
  });
}
