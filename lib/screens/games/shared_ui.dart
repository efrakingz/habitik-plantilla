import 'package:flutter/material.dart';

typedef SubmitChallengeFunc = Future<void> Function(
  String id, 
  String title, 
  int xp, 
  int monedas, 
  List<String> evidencias, 
  bool requiereEvidencia, 
  String color
);

class ChallengeShell extends StatelessWidget {
  final Color color;
  final String title;
  final VoidCallback onClose;
  final Widget child;
  final Widget? extra;

  const ChallengeShell({
    super.key,
    required this.color,
    required this.title,
    required this.onClose,
    required this.child,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: color,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: onClose, 
                child: Container(
                  width: 32, 
                  height: 32, 
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), 
                  child: const Icon(Icons.close, color: Colors.white, size: 18)
                )
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
              if (extra != null) extra!,
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ],
    );
  }
}

class RewardStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const RewardStat({super.key, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
      ],
    );
  }
}
