import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/models/task_model.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  DateTime _selectedDate = DateTime.now();

  // Helper to generate a list of 7 days around the selected date
  List<DateTime> _generateWeekDays() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      return today.add(Duration(days: index - 3));
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksStream = ref.watch(todayTasksProvider);
    final theme = Theme.of(context);
    final weekDays = _generateWeekDays();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go(AppRouter.routeDashboard),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Horizontal Calendar Selector
            Container(
              height: 90,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: weekDays.length,
                itemBuilder: (context, index) {
                  final day = weekDays[index];
                  final isSelected = DateUtils.isSameDay(day, _selectedDate);
                  final dayLabel = DateFormat('E').format(day).toUpperCase();
                  final dateLabel = DateFormat('d').format(day);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDate = day;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white70
                                    : theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Tasks List
            Expanded(
              child: tasksStream.when(
                data: (tasks) {
                  // Filter tasks by selected date locally
                  final filteredTasks = tasks.where((task) {
                    return DateUtils.isSameDay(task.date, _selectedDate);
                  }).toList();

                  // Sort tasks: pending first, then by priority (High -> Medium -> Low)
                  filteredTasks.sort((a, b) {
                    if (a.status != b.status) {
                      return a.status == TaskStatus.pending ? -1 : 1;
                    }
                    return b.priority.index.compareTo(a.priority.index);
                  });

                  if (filteredTasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.playlist_add_check_rounded,
                            size: 72,
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All caught up!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No tasks listed for this day.',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return TaskCard(task: task);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text('Error loading tasks: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRouter.routeAddTask),
        child: const Icon(Icons.add),
      ),
    );
  }
}
