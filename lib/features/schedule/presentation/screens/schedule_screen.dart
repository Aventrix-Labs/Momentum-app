import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/models/schedule_model.dart';
import '../providers/schedule_providers.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  List<DateTime> _generateWeekDays() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      return today.add(Duration(days: index - 3));
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  // Opens bottom sheet to add or edit a schedule item
  void _openScheduleBottomSheet({ScheduleModel? scheduleToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ScheduleFormBottomSheet(
          selectedDate: _selectedDate,
          scheduleToEdit: scheduleToEdit,
          onSuccess: (msg) {
            _showSnackBar(msg, isError: false);
          },
          onError: (msg) {
            _showSnackBar(msg, isError: true);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleStream = ref.watch(dateScheduleProvider(_selectedDate));
    final theme = Theme.of(context);
    final weekDays = _generateWeekDays();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
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

            // Schedule Timeline list
            Expanded(
              child: scheduleStream.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items scheduled',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Keep your day organized. Add some events!',
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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.startTime,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.endTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: (item.note != null && item.note!.isNotEmpty)
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    item.note!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _openScheduleBottomSheet(scheduleToEdit: item),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: theme.colorScheme.error,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete schedule'),
                                      content: const Text('Are you sure you want to delete this schedule item?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(color: theme.colorScheme.error),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await ref
                                        .read(scheduleControllerProvider.notifier)
                                        .deleteSchedule(item.id);
                                    _showSnackBar('Schedule deleted successfully.', isError: false);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text('Error loading schedule: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openScheduleBottomSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ScheduleFormBottomSheet extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final ScheduleModel? scheduleToEdit;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _ScheduleFormBottomSheet({
    required this.selectedDate,
    this.scheduleToEdit,
    required this.onSuccess,
    required this.onError,
  });

  @override
  ConsumerState<_ScheduleFormBottomSheet> createState() => _ScheduleFormBottomSheetState();
}

class _ScheduleFormBottomSheetState extends ConsumerState<_ScheduleFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  String _startTime = '09:00';
  String _endTime = '10:00';

  @override
  void initState() {
    super.initState();
    if (widget.scheduleToEdit != null) {
      final item = widget.scheduleToEdit!;
      _titleController.text = item.title;
      _noteController.text = item.note ?? '';
      _startTime = item.startTime;
      _endTime = item.endTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final initialStr = isStart ? _startTime : _endTime;
    final initialTime = TimeOfDay(
      hour: int.parse(initialStr.split(':')[0]),
      minute: int.parse(initialStr.split(':')[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startTime = timeStr;
        } else {
          _endTime = timeStr;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startTime.compareTo(_endTime) >= 0) {
      widget.onError('Start time must be before end time.');
      return;
    }

    final isEdit = widget.scheduleToEdit != null;

    final schedule = ScheduleModel(
      id: isEdit ? widget.scheduleToEdit!.id : '',
      userId: isEdit ? widget.scheduleToEdit!.userId : '',
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      date: widget.selectedDate,
      startTime: _startTime,
      endTime: _endTime,
      createdAt: isEdit ? widget.scheduleToEdit!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (isEdit) {
        await ref.read(scheduleControllerProvider.notifier).updateSchedule(schedule);
        widget.onSuccess('Schedule updated successfully!');
      } else {
        await ref.read(scheduleControllerProvider.notifier).createSchedule(schedule);
        widget.onSuccess('Schedule created successfully!');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(scheduleControllerProvider).isLoading;
    final isEdit = widget.scheduleToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Schedule' : 'New Schedule',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Schedule Title',
                prefixIcon: Icon(Icons.event_note_rounded),
              ),
              validator: (val) => Validators.validateRequired(val, 'Title'),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),

            // Time Selection
            Row(
              children: [
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      leading: Icon(Icons.access_time_rounded, color: theme.colorScheme.primary),
                      title: const Text('Start'),
                      subtitle: Text(_startTime),
                      onTap: isLoading ? null : () => _selectTime(true),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      leading: Icon(Icons.access_time_filled_rounded, color: theme.colorScheme.primary),
                      title: const Text('End'),
                      subtitle: Text(_endTime),
                      onTap: isLoading ? null : () => _selectTime(false),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Note (Optional)
            TextFormField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 28),

            // Save Button
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(isEdit ? 'Save Changes' : 'Add to Schedule'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
