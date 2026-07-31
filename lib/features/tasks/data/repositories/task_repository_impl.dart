import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/task_model.dart';
import '../../domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final SupabaseClient _supabase;

  TaskRepositoryImpl(this._supabase);

  @override
  Future<List<TaskModel>> getTasks(DateTime date) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final dateStr = date.toIso8601String().split('T')[0];
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr);

    return (response as List).map((json) => TaskModel.fromJson(json)).toList();
  }

  @override
  Stream<List<TaskModel>> watchTasks(DateTime date) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    final dateStr = date.toIso8601String().split('T')[0];
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((maps) {
          // Locally filter by date to ensure compatibility with complex stream queries
          return maps
              .map((json) => TaskModel.fromJson(json))
              .where((task) => task.date.toIso8601String().split('T')[0] == dateStr)
              .toList();
        });
  }

  @override
  Future<void> createTask(TaskModel task) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final json = task.toJson();
    json['user_id'] = userId;
    if (task.id.isEmpty) {
      json.remove('id');
    }

    await _supabase.from('tasks').insert(json);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final json = task.toJson();
    json['user_id'] = userId;

    await _supabase
        .from('tasks')
        .update(json)
        .eq('id', task.id);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }
}
