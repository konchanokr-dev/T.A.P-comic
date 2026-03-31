import 'package:flutter/material.dart';

class NameAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const NameAvatar({super.key, required this.name, this.radius = 20});

  Color _bgColor() {
    const colors = [
      Color(0xFFB5D4F4), Color(0xFF9FE1CB), Color(0xFFCECBF6),
      Color(0xFFFAC775), Color(0xFFF4C0D1), Color(0xFFF5C4B3),
      Color(0xFFC0DD97),
    ];
    int h = 0;
    for (final c in name.codeUnits) h = (h * 31 + c) % colors.length;
    return colors[h.abs() % colors.length];
  }

  Color _fgColor() {
    const colors = [
      Color(0xFF0C447C), Color(0xFF085041), Color(0xFF3C3489),
      Color(0xFF633806), Color(0xFF72243E), Color(0xFF712B13),
      Color(0xFF27500A),
    ];
    int h = 0;
    for (final c in name.codeUnits) h = (h * 31 + c) % colors.length;
    return colors[h.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: _bgColor(),
      child: Text(
        initial,
        style: TextStyle(
          color: _fgColor(),
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}