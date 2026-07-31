import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

enum TaskPriority {
  @JsonValue('High')
  high,
  @JsonValue('Medium')
  medium,
  @JsonValue('Low')
  low,
}

enum TaskStatus {
  @JsonValue('Pending')
  pending,
  @JsonValue('Completed')
  completed,
}

@freezed
class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String title,
    String? description,
    @Default(TaskPriority.medium) TaskPriority priority,
    @Default(TaskStatus.pending) TaskStatus status,
    @Default('General') String category,
    required DateTime date,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);
}
