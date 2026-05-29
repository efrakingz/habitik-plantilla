import 'package:flutter/material.dart';
import '../config/theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final bool isJefe;

  const BottomNav({super.key, required this.currentIndex, required this.onTap, this.isJefe = false});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Inicio', Icons.home_outlined, Icons.home, 0),
      ('Retos', Icons.videogame_asset_outlined, Icons.videogame_asset, 1),
      if (isJefe) ('Boletas', Icons.camera_alt_outlined, Icons.camera_alt, 2),
      ('Canjes', Icons.card_giftcard_outlined, Icons.card_giftcard, 3),
      if (isJefe) ('Control', Icons.bar_chart_outlined, Icons.bar_chart, 4),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.green100, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: items.map((item) {
          final tabIndex = item.$4;
          final selected = currentIndex == tabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(tabIndex),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.green100 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      selected ? item.$3 : item.$2,
                      color: selected ? AppTheme.green700 : Colors.grey.shade400,
                      size: 22,
                    ),
                  ),
                  Text(
                    item.$1,
                    style: TextStyle(
                      color: selected ? AppTheme.green700 : Colors.grey.shade400,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
