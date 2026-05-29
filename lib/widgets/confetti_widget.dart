import 'package:flutter/material.dart';
import 'dart:math';
import '../config/theme.dart';

class ConfettiWidget extends StatefulWidget {
  final bool play;
  const ConfettiWidget({super.key, required this.play});

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Widget> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void didUpdateWidget(ConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _generateParticles();
      _controller.forward(from: 0);
    }
  }

  void _generateParticles() {
    final rng = Random();
    _particles.clear();
    for (var i = 0; i < 30; i++) {
      _particles.add(TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 800 + rng.nextInt(1200)),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(
              sin(value * 3 + i) * 80,
              value * -200 + rng.nextDouble() * 40,
            ),
            child: Transform.rotate(
              angle: value * 6,
              child: Opacity(opacity: 1 - value, child: child),
            ),
          );
        },
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: [AppTheme.green500, AppTheme.amber400, AppTheme.blue700, AppTheme.red700, Colors.purple][rng.nextInt(5)],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.play) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: _particles,
        ),
      ),
    );
  }
}
