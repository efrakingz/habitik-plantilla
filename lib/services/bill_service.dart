import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class BillService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<BillData>> getBills(String familyId) async {
    final response = await _client
        .from('bills')
        .select()
        .eq('family_id', familyId)
        .order('created_at', ascending: false);

    return (response as List).map((data) => BillData.fromJson(data)).toList();
  }

  Future<void> createBill(BillData bill) async {
    await _client.from('bills').insert({
      'family_id': bill.familyId,
      'tipo': bill.tipo,
      'consumo': bill.consumo,
      'monto': bill.monto,
      'periodo': bill.periodo,
      'empresa': bill.empresa,
      'cuenta': bill.cuenta,
      'tarifa': bill.tarifa,
      'imagen_url': bill.imagenUrl,
    });
  }

  Future<void> deleteBill(String id) async {
    await _client.from('bills').delete().eq('id', id);
  }
}
