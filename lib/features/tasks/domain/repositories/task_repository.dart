import '../../domain/models/task_model.dart';

abstract class TaskRepository {
  Future<List<TaskModel>> getTasks(DateTime date);
  Stream<List<TaskModel>> watchTasks(DateTime date);
  Future<void> createTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String taskId);
}
