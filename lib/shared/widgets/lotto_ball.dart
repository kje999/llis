import 'dart:math';
import 'package:flutter/material.dart';

class LottoBall extends StatelessWidget {
  final int number;
  final double size;
  final Color? color;
  final bool isHighlighted;

  const LottoBall({
    super.key,
    required this.number,
    this.size = 42,
    this.color,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final ballColor = color ?? _getBallColor(number);

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [
            Colors.white,
            ballColor,
            ballColor.withOpacity(0.85),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(2, 3),
            blurRadius: 4,
          ),
          if (isHighlighted)
            BoxShadow(
              color: Colors.amber.withOpacity(0.8),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString().padLeft(2, '0'),
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.42,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Color _getBallColor(int n) {
    if (n <= 10) return const Color(0xFFFBBF24); // Gold / Yellow
    if (n <= 20) return const Color(0xFF60A5FA); // Blue
    if (n <= 30) return const Color(0xFFF87171); // Red
    if (n <= 40) return const Color(0xFF34D399); // Green
    if (n <= 50) return const Color(0xFFA78BFA); // Purple
    return const Color(0xFFF472B6);              // Pink (51-58)
  }
}
