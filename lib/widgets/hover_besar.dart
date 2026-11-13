import 'package:flutter/material.dart';

/// Membungkus widget (misalnya tombol) supaya membesar halus saat kursor
/// mengarah ke atasnya, dan sedikit mengecil saat ditekan.
///
/// Contoh: HoverBesar(child: FilledButton(...))
class HoverBesar extends StatefulWidget {
  final Widget child;

  /// Seberapa besar saat kursor di atasnya (1.06 = 6% lebih besar).
  final double skala;

  const HoverBesar({super.key, required this.child, this.skala = 1.06});

  @override
  State<HoverBesar> createState() => _HoverBesarState();
}

class _HoverBesarState extends State<HoverBesar> {
  bool _hover = false;
  bool _tekan = false;

  @override
  Widget build(BuildContext context) {
    final skala = _tekan ? 0.97 : (_hover ? widget.skala : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _tekan = false;
      }),
      child: Listener(
        onPointerDown: (_) => setState(() => _tekan = true),
        onPointerUp: (_) => setState(() => _tekan = false),
        onPointerCancel: (_) => setState(() => _tekan = false),
        child: AnimatedScale(
          scale: skala,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}