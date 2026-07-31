import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/models/task_model.dart';
import '../../domain/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TaskRepositoryImpl(client);
});

// A stream provider that watches ALL tasks for the logged in user
final allUserTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final authState = ref.watch(supabaseAuthStateProvider);
  
  if (authState.value?.session == null) {
    return Stream.value(<TaskModel>[]);
  }
  
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);
  
  return client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((maps) => maps.map((json) => TaskModel.fromJson(json)).toList());
});

// A stream provider that watches tasks for today specifically
final todayTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final authState = ref.watch(supabaseAuthStateProvider);
  
  if (authState.value?.session == null) {
    return Stream.value(<TaskModel>[]);
  }
  
  return repository.watchTasks(DateTime.now());
});

// State provider for the search query on the dashboard
final searchQueryProvider = StateProvider<String>((ref) => '');

// State provider for the selected filter chip
// Options: 'All', 'Today', 'Tomorrow', 'This Week', 'Completed', 'Pending'
final selectedFilterProvider = StateProvider<String>((ref) => 'All');

// A derived provider that applies search and filters to the user's tasks
final filteredTasksProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  final allTasksAsync = ref.watch(allUserTasksProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final filter = ref.watch(selectedFilterProvider);
  
  return allTasksAsync.whenData((tasks) {
    var result = tasks;
    
    // 1. Apply Horizontal Filter Chip
    final now = DateTime.now();
    
    if (filter == 'Today') {
      result = result.where((t) => DateUtils.isSameDay(t.date, now)).toList();
    } else if (filter == 'Tomorrow') {
      final tomorrow = now.add(const Duration(days: 1));
      result = result.where((t) => DateUtils.isSameDay(t.date, tomorrow)).toList();
    } else if (filter == 'This Week') {
      // Find start and end of current week
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      result = result.where((t) {
        final taskDate = DateUtils.dateOnly(t.date);
        return (taskDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
                taskDate.isBefore(endOfWeek.add(const Duration(days: 1))));
      }).toList();
    } else if (filter == 'Completed') {
      result = result.where((t) => t.status == TaskStatus.completed).toList();
    } else if (filter == 'Pending') {
      result = result.where((t) => t.status == TaskStatus.pending).toList();
    }
    
    // 2. Apply Realtime Search Bar Query
    if (query.isNotEmpty) {
      result = result.where((t) {
        final titleMatch = t.title.toLowerCase().contains(query);
        final descMatch = t.description?.toLowerCase().contains(query) ?? false;
        final catMatch = t.category.toLowerCase().contains(query);
        return titleMatch || descMatch || catMatch;
      }).toList();
    }
    
    // Default sorting: pending first, then by priority (High -> Medium -> Low), then by time
    result.sort((a, b) {
      if (a.status != b.status) {
        return a.status == TaskStatus.pending ? -1 : 1;
      }
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      
      final aTime = a.startTime ?? '99:99';
      final bTime = b.startTime ?? '99:99';
      return aTime.compareTo(bTime);
    });
    
    return result;
  });
});

// A derived provider for upcoming tasks (max 5)
final upcomingTasksProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  final allTasksAsync = ref.watch(allUserTasksProvider);
  
  return allTasksAsync.whenData((tasks) {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    
    final upcoming = tasks.where((task) {
      final taskDateStr = task.date.toIso8601String().split('T')[0];
      
      // Keep if date is strictly in the future OR (is today and pending)
      if (task.date.isAfter(now)) {
        return true;
      }
      return taskDateStr == todayStr && task.status == TaskStatus.pending;
    }).toList();
    
    // Sort upcoming tasks chronologically
    upcoming.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      
      final aTime = a.startTime ?? '99:99';
      final bTime = b.startTime ?? '99:99';
      return aTime.compareTo(bTime);
    });
    
    return upcoming.take(5).toList();
  });
});

// A future provider to fetch a single task by ID (for edit screen)
final singleTaskProvider = FutureProvider.family<TaskModel?, String>((ref, id) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('tasks')
      .select()
      .eq('id', id)
      .maybeSingle();

  if (response == null) return null;
  return TaskModel.fromJson(response);
});

class TaskStats {
  final int total;
  final int completed;
  final int remaining;
  final double percentage;

  const TaskStats({
    required this.total,
    required this.completed,
    required this.remaining,
    required this.percentage,
  });

  factory TaskStats.empty() => const TaskStats(
        total: 0,
        completed: 0,
        remaining: 0,
        percentage: 0.0,
      );
}

// A derived provider for today's statistics
final todayStatsProvider = Provider<TaskStats>((ref) {
  final tasksAsync = ref.watch(todayTasksProvider);
  
  return tasksAsync.maybeWhen(
    data: (tasks) {
      if (tasks.isEmpty) return TaskStats.empty();
      final total = tasks.length;
      final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
      final remaining = total - completed;
      final percentage = completed / total;
      
      return TaskStats(
        total: total,
        completed: completed,
        remaining: remaining,
        percentage: percentage,
      );
    },
    orElse: () => TaskStats.empty(),
  );
});

class TaskController extends StateNotifier<AsyncValue<void>> {
  final TaskRepository _repository;

  TaskController(this._repository) : super(const AsyncValue.data(null));

  Future<void> createTask(TaskModel task) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createTask(task);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTask(task);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleTaskStatus(TaskModel task) async {
    final updated = task.copyWith(
      status: task.status == TaskStatus.completed
          ? TaskStatus.pending
          : TaskStatus.completed,
      updatedAt: DateTime.now(),
    );
    try {
      await _repository.updateTask(updated);
    } catch (e) {
      debugPrint('Error toggling task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTask(taskId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final taskControllerProvider =
    StateNotifierProvider<TaskController, AsyncValue<void>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskController(repository);
});
