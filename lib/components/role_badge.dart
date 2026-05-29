import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final String rol;

  const RoleBadge({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg; String text;
    final r = rol.toLowerCase();
    if (r == 'jefe' || r == 'jefa' || r == 'jefa de familia') {
      bg = const Color(0xFFFFECB3); fg = const Color(0xFFF57C00); text = '👑 Jefe';
    } else if (r == 'papa' || r == 'papá') {
      bg = const Color(0xFFBBDEFB); fg = const Color(0xFF1976D2); text = '👨 Papá';
    } else if (r == 'hija') {
      bg = const Color(0xFFF8BBD0); fg = const Color(0xFFC2185B); text = '👧 Hija';
    } else if (r == 'hijo') {
      bg = const Color(0xFFE1BEE7); fg = const Color(0xFF7B1FA2); text = '👦 Hijo';
    } else if (r == 'co-admin' || r == 'coadmin') {
      bg = const Color(0xFFBBDEFB); fg = const Color(0xFF1976D2); text = '⭐ Co-Admin';
    } else {
      bg = const Color(0xFFE1BEE7); fg = const Color(0xFF7B1FA2); text = '👦 Miembro';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
