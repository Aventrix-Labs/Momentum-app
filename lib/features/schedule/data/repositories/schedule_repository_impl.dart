import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/schedule_model.dart';
import '../../domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final SupabaseClient _supabase;

  ScheduleRepositoryImpl(this._supabase);

  @override
  Future<List<ScheduleModel>> getSchedule(DateTime date) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final dateStr = date.toIso8601String().split('T')[0];
    final response = await _supabase
        .from('schedule')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('start_time', ascending: true);

    return (response as List).map((json) => ScheduleModel.fromJson(json)).toList();
  }

  @override
  Stream<List<ScheduleModel>> watchSchedule(DateTime date) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    final dateStr = date.toIso8601String().split('T')[0];
    return _supabase
        .from('schedule')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((maps) {
          final list = maps
              .map((json) => ScheduleModel.fromJson(json))
              .where((item) => item.date.toIso8601String().split('T')[0] == dateStr)
              .toList();
          
          // Sort locally by start_time
          list.sort((a, b) => a.startTime.compareTo(b.startTime));
          return list;
        });
  }

  @override
  Future<void> createSchedule(ScheduleModel schedule) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final json = schedule.toJson();
    json['user_id'] = userId;
    if (schedule.id.isEmpty) {
      json.remove('id');
    }

    await _supabase.from('schedule').insert(json);
  }

  @override
  Future<void> updateSchedule(ScheduleModel schedule) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final json = schedule.toJson();
    json['user_id'] = userId;

    await _supabase
        .from('schedule')
        .update(json)
        .eq('id', schedule.id);
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    await _supabase.from('schedule').delete().eq('id', scheduleId);
  }
}
