import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../domain/models/schedule_model.dart';
import '../../domain/repositories/schedule_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ScheduleRepositoryImpl(client);
});

// A stream provider that watches schedule items for today
final todayScheduleProvider = StreamProvider<List<ScheduleModel>>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  final authState = ref.watch(supabaseAuthStateProvider);
  
  if (authState.value?.session == null) {
    return Stream.value(<ScheduleModel>[]);
  }
  
  return repository.watchSchedule(DateTime.now());
});

// A stream provider that watches schedule items for a specific date
final dateScheduleProvider = StreamProvider.family<List<ScheduleModel>, DateTime>((ref, date) {
  final repository = ref.watch(scheduleRepositoryProvider);
  final authState = ref.watch(supabaseAuthStateProvider);
  
  if (authState.value?.session == null) {
    return Stream.value(<ScheduleModel>[]);
  }
  
  return repository.watchSchedule(date);
});

// A future provider to fetch a single schedule item by ID (for editing)
final singleScheduleProvider = FutureProvider.family<ScheduleModel?, String>((ref, id) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('schedule')
      .select()
      .eq('id', id)
      .maybeSingle();

  if (response == null) return null;
  return ScheduleModel.fromJson(response);
});

// A provider that gets the next upcoming schedule item for today
final nextUpcomingScheduleProvider = Provider<ScheduleModel?>((ref) {
  final scheduleAsync = ref.watch(todayScheduleProvider);
  
  return scheduleAsync.maybeWhen(
    data: (items) {
      if (items.isEmpty) return null;
      
      final now = DateTime.now();
      final nowStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      try {
        return items.firstWhere(
          (item) => item.startTime.compareTo(nowStr) >= 0,
        );
      } catch (_) {
        return null;
      }
    },
    orElse: () => null,
  );
});

class ScheduleController extends StateNotifier<AsyncValue<void>> {
  final ScheduleRepository _repository;
  final Ref _ref;

  ScheduleController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> createSchedule(ScheduleModel schedule) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createSchedule(schedule);
      
      // Schedule reminder if notifications are enabled
      final settings = _ref.read(settingsProvider);
      if (settings.isNotificationsEnabled) {
        await NotificationService().scheduleScheduleReminder(schedule);
      }
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateSchedule(schedule);
      
      // Cancel previous reminder and schedule new one if enabled
      await NotificationService().cancelScheduleReminder(schedule.id);
      final settings = _ref.read(settingsProvider);
      if (settings.isNotificationsEnabled) {
        await NotificationService().scheduleScheduleReminder(schedule);
      }
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteSchedule(scheduleId);
      
      // Cancel reminder
      await NotificationService().cancelScheduleReminder(scheduleId);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final scheduleControllerProvider =
    StateNotifierProvider<ScheduleController, AsyncValue<void>>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return ScheduleController(repository, ref);
});
