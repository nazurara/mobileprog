import 'package:flutter/material.dart';

import 'pages/home_page.dart';

void main() => runApp(const LapakKuApp());

class LapakKuApp extends StatelessWidget {
  const LapakKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LapakKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const HomePage(),
    );
  }
}
