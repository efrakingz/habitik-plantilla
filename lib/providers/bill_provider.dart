import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/bill_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';

class BillProvider with ChangeNotifier {
  final BillService _billService = BillService();

  List<BillData> _bills = [];
  bool _isLoading = false;
  String? _error;

  List<BillData> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Returns last bill by type
  BillData? lastBill(String tipo) {
    final byType = _bills.where((b) => b.tipo == tipo).toList();
    return byType.isNotEmpty ? byType.first : null;
  }

  // Returns second-to-last bill (the "previous" one for comparison)
  BillData? previousBill(String tipo) {
    final byType = _bills.where((b) => b.tipo == tipo).toList();
    return byType.length > 1 ? byType[1] : null;
  }

  /// Calculates % change between last two bills. Negative = reduction (good).
  double? consumoChangePercent(String tipo) {
    final last = lastBill(tipo);
    final prev = previousBill(tipo);
    if (last == null || prev == null) return null;

    final lastVal = _parseConsumo(last.consumo);
    final prevVal = _parseConsumo(prev.consumo);
    if (prevVal <= 0) return null;

    return ((lastVal - prevVal) / prevVal) * 100;
  }

  /// Calculates XP earned for a bill (fixed to 25 XP as per requirements).
  int xpForBill(String tipo) {
    return 25;
  }

  /// Checks if consumption exceeds the family meta (% reduction target).
  bool exceedsMeta(String tipo, int metaPercent) {
    final change = consumoChangePercent(tipo);
    if (change == null) return false;
    // If not achieving the required reduction, it exceeds meta
    return change > -(metaPercent.toDouble());
  }

  /// Returns computed savings amount as a formatted string.
  String savingsAmount(String tipo) {
    final last = lastBill(tipo);
    final prev = previousBill(tipo);
    if (last == null || prev == null) return '\$0';

    final lastMonto = _parseMonto(last.monto);
    final prevMonto = _parseMonto(prev.monto);
    final diff = prevMonto - lastMonto;
    if (diff <= 0) return '\$0';

    return '\$${diff.toStringAsFixed(0)}';
  }

  /// Returns aggregate saving across all bill types.
  String totalSavings() {
    double total = 0;
    for (final tipo in ['luz', 'agua']) {
      final last = lastBill(tipo);
      final prev = previousBill(tipo);
      if (last != null && prev != null) {
        final diff = _parseMonto(prev.monto) - _parseMonto(last.monto);
        if (diff > 0) total += diff;
      }
    }
    if (total == 0) return '\$0';
    return '\$${total.toStringAsFixed(0)}';
  }

  /// Overall family energy % (how close to meeting both metas, 0–100).
  double familyEnergyPercent(int metaLuz, int metaAgua) {
    double score = 0;
    int count = 0;

    for (final entry in [
      {'tipo': 'luz', 'meta': metaLuz},
      {'tipo': 'agua', 'meta': metaAgua},
    ]) {
      final tipo = entry['tipo'] as String;
      final meta = entry['meta'] as int;
      final change = consumoChangePercent(tipo);
      if (change != null) {
        // Score: how much of the meta is achieved, capped at 100%
        final achieved = (-change / meta).clamp(0.0, 1.0);
        score += achieved;
        count++;
      }
    }

    if (count == 0) return 0.5; // No data, show 50% as neutral
    return score / count;
  }

  double _parseConsumo(String raw) {
    // Extract numeric value: "380 kWh" → 380, "22 m³" → 22
    final match = RegExp(r'[\d,.]+').firstMatch(raw.replaceAll(',', ''));
    return match != null ? double.tryParse(match.group(0)!) ?? 0 : 0;
  }

  double _parseMonto(String raw) {
    // Extract numeric: "$1,240.50" → 1240.50
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  Future<void> loadBills(String familyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bills = await _billService.getBills(familyId);
    } catch (e) {
      _error = e.toString();
      // Load mock data if DB fails
      _bills = _mockBills();
    } finally {
      // Filter out locally deleted bills
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList('deleted_bills') ?? [];
      _bills.removeWhere((b) => deletedIds.contains(b.id));

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBill(
    BillData bill, {
    AchievementProvider? achievementProvider,
    AuthProvider? authProvider,
  }) async {
    try {
      await _billService.createBill(bill);
      if (bill.familyId != null) {
        await loadBills(bill.familyId!);
      } else {
        // Insert locally for preview
        _bills.insert(0, bill);
        notifyListeners();
      }

      // Trigger achievements
      if (achievementProvider != null && authProvider != null) {
        final userId = authProvider.profile?.id;
        if (userId != null) {
          achievementProvider.checkAndUnlock(userId, 'primer_recibo', authProvider: authProvider).ignore();

          final luzCount = _bills.where((b) => b.tipo == 'luz').length;
          final aguaCount = _bills.where((b) => b.tipo == 'agua').length;

          if (luzCount >= 3) {
            achievementProvider.checkAndUnlock(userId, 'ahorro_luz', authProvider: authProvider).ignore();
          }
          if (aguaCount >= 3) {
            achievementProvider.checkAndUnlock(userId, 'ahorro_agua', authProvider: authProvider).ignore();
          }
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBill(String id) async {
    try {
      await _billService.deleteBill(id);
      _bills.removeWhere((b) => b.id == id);
      
      final prefs = await SharedPreferences.getInstance();
      final deleted = prefs.getStringList('deleted_bills') ?? [];
      deleted.add(id);
      await prefs.setStringList('deleted_bills', deleted);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      // Even if DB delete fails (e.g. mock bills or RLS error), delete it locally
      _bills.removeWhere((b) => b.id == id);

      final prefs = await SharedPreferences.getInstance();
      final deleted = prefs.getStringList('deleted_bills') ?? [];
      deleted.add(id);
      await prefs.setStringList('deleted_bills', deleted);

      notifyListeners();
      return false;
    }
  }

  List<BillData> _mockBills() {
    return [
      BillData(id: 'm1', tipo: 'luz', consumo: '310 kWh', monto: '\$1,020.00', periodo: 'Mar-Abr 2025', empresa: 'CFE', cuenta: '52103-00421', tarifa: 'DAC'),
      BillData(id: 'm2', tipo: 'luz', consumo: '380 kWh', monto: '\$1,240.50', periodo: 'Feb-Mar 2025', empresa: 'CFE', cuenta: '52103-00421', tarifa: 'DAC'),
      BillData(id: 'm3', tipo: 'agua', consumo: '18 m³', monto: '\$480.00', periodo: 'Mar-Abr 2025', empresa: 'SAPAM', cuenta: '83-004-21', tarifa: 'Dom'),
      BillData(id: 'm4', tipo: 'agua', consumo: '22 m³', monto: '\$580.00', periodo: 'Feb-Mar 2025', empresa: 'SAPAM', cuenta: '83-004-21', tarifa: 'Dom'),
    ];
  }

  void clear() {
    _bills = [];
    notifyListeners();
  }
}
