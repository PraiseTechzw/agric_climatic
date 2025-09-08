import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/farm.dart';

class FarmService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Farm>> getFarms() async {
    try {
      final response = await _supabase
          .from('farms')
          .select()
          .order('created_at', ascending: false);

      return response.map((json) => Farm.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch farms: $e');
    }
  }

  Future<Farm> addFarm(Farm farm) async {
    try {
      final response =
          await _supabase.from('farms').insert(farm.toJson()).select().single();

      return Farm.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add farm: $e');
    }
  }

  Future<void> updateFarm(Farm farm) async {
    try {
      await _supabase.from('farms').update(farm.toJson()).eq('id', farm.id);
    } catch (e) {
      throw Exception('Failed to update farm: $e');
    }
  }

  Future<void> deleteFarm(String farmId) async {
    try {
      await _supabase.from('farms').delete().eq('id', farmId);
    } catch (e) {
      throw Exception('Failed to delete farm: $e');
    }
  }
}
