import 'package:flutter/material.dart';
import '../config/theme.dart';

class AvatarBadge extends StatelessWidget {
  final String letter;
  final String colorHex;
  final String? avatarUrl;
  final double radius;

  const AvatarBadge({
    super.key,
    required this.letter,
    required this.colorHex,
    this.avatarUrl,
    this.radius = 16,
  });

  Color _parseColor(String hex) {
    try {
      if (hex.isEmpty) return AppTheme.green600;
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.green600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parseColor(colorHex);
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: bg,
        onBackgroundImageError: (e, s) => debugPrint('Error loading avatar'),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(letter, style: TextStyle(color: Colors.white, fontSize: radius * 0.75, fontWeight: FontWeight.w900)),
    );
  }
}
