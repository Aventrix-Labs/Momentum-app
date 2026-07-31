import '../../domain/models/schedule_model.dart';

abstract class ScheduleRepository {
  Future<List<ScheduleModel>> getSchedule(DateTime date);
  Stream<List<ScheduleModel>> watchSchedule(DateTime date);
  Future<void> createSchedule(ScheduleModel schedule);
  Future<void> updateSchedule(ScheduleModel schedule);
  Future<void> deleteSchedule(String scheduleId);
}
