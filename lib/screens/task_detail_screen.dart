import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/tag.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/tag_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/tag_chip.dart';
import '../widgets/priority_indicator.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String? taskId;

  const TaskDetailScreen({super.key, this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _uuid = const Uuid();

  DateTime? _dueDate;
  int? _estimatedMinutes;
  int _priority = 0;
  DateTime? _reminderAt;
  List<Tag> _selectedTags = [];
  bool _isNew = false;
  Task? _task;

  @override
  void initState() {
    super.initState();
    _isNew = widget.taskId == null || widget.taskId == 'new';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _loadTask(Task task) {
    if (_task?.id == task.id && _titleController.text.isNotEmpty) return;
    _task = task;
    _titleController.text = task.title;
    _descController.text = task.description ?? '';
    _dueDate = task.dueDate;
    _estimatedMinutes = task.estimatedMinutes;
    _priority = task.priority;
    _reminderAt = task.reminderAt;
    _selectedTags = List.from(task.tags);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);
    final allTags = ref.watch(tagListProvider);
    final subtaskFilter = ref.watch(subtaskFilterProvider);

    Task? task;
    if (!_isNew) {
      task = tasksAsync.whenData((tasks) {
        try {
          return tasks.firstWhere((t) => t.id == widget.taskId);
        } catch (_) {
          return null;
        }
      }).valueOrNull;

      if (task != null) {
        _loadTask(task);
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'タスク名を入力...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: _descController,
                          maxLines: null,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: '説明を追加...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Properties
                      _buildPropertySection(allTags),
                      // Subtasks section (only for existing tasks)
                      if (!_isNew && task != null) ...[
                        const SizedBox(height: 24),
                        _buildSubtaskSection(task, subtaskFilter, allTags),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
              onPressed: _deleteTask,
            ),
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.accentGreen),
            onPressed: _saveTask,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySection(AsyncValue<List<Tag>> allTags) {
    return GlassCard(
      child: Column(
        children: [
          // Due date
          _buildPropertyRow(
            icon: Icons.calendar_today,
            label: '期限',
            value: _dueDate != null
                ? DateFormat('yyyy/MM/dd').format(_dueDate!)
                : '未設定',
            valueColor: _dueDate != null &&
                    _dueDate!.isBefore(DateTime.now())
                ? AppTheme.accentRed
                : null,
            onTap: _pickDueDate,
            onClear: _dueDate != null
                ? () => setState(() => _dueDate = null)
                : null,
          ),
          const Divider(color: AppTheme.glassBorder, height: 1),
          // Estimated time
          _buildPropertyRow(
            icon: Icons.access_time,
            label: '見込み時間',
            value: _estimatedMinutes != null
                ? _formatMinutes(_estimatedMinutes!)
                : '未設定',
            onTap: _pickEstimatedTime,
            onClear: _estimatedMinutes != null
                ? () => setState(() => _estimatedMinutes = null)
                : null,
          ),
          const Divider(color: AppTheme.glassBorder, height: 1),
          // Priority
          _buildPropertyRow(
            icon: Icons.flag,
            label: '優先度',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _priority = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _priority == i
                          ? AppTheme.getPriorityColor(i).withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _priority == i
                            ? AppTheme.getPriorityColor(i)
                            : AppTheme.glassBorder,
                      ),
                    ),
                    child: Text(
                      ['なし', '低', '中', '高'][i],
                      style: TextStyle(
                        color: _priority == i
                            ? AppTheme.getPriorityColor(i)
                            : AppTheme.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(color: AppTheme.glassBorder, height: 1),
          // Reminder (only on non-web)
          if (!kIsWeb) ...[
            _buildPropertyRow(
              icon: Icons.notifications_outlined,
              label: 'リマインダー',
              value: _reminderAt != null
                  ? DateFormat('MM/dd HH:mm').format(_reminderAt!)
                  : '未設定',
              onTap: _pickReminder,
              onClear: _reminderAt != null
                  ? () => setState(() => _reminderAt = null)
                  : null,
            ),
            const Divider(color: AppTheme.glassBorder, height: 1),
          ],
          // Tags
          _buildTagsRow(allTags),
        ],
      ),
    );
  }

  Widget _buildPropertyRow({
    required IconData icon,
    required String label,
    String? value,
    Color? valueColor,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (trailing != null)
              trailing
            else if (value != null)
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            if (onClear != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close,
                      size: 16, color: AppTheme.textTertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsRow(AsyncValue<List<Tag>> allTagsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.label_outline,
                  size: 20, color: AppTheme.textSecondary),
              const SizedBox(width: 12),
              const Text(
                'タグ',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showTagPicker(allTagsAsync),
                child: const Icon(Icons.add,
                    size: 20, color: AppTheme.primaryColor),
              ),
            ],
          ),
          if (_selectedTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _selectedTags
                  .map((tag) => TagChip(
                        tag: tag,
                        onDelete: () {
                          setState(() {
                            _selectedTags.remove(tag);
                          });
                        },
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtaskSection(
    Task task,
    SubTaskFilterState filter,
    AsyncValue<List<Tag>> allTags,
  ) {
    var subtasks = List<SubTask>.from(task.subtasks);

    // Filter
    if (filter.priorityFilter != null) {
      subtasks = subtasks
          .where((s) => s.priority == filter.priorityFilter)
          .toList();
    }
    if (filter.tagFilter != null) {
      subtasks = subtasks
          .where((s) => s.tags.any((t) => t.id == filter.tagFilter))
          .toList();
    }

    // Sort
    subtasks.sort((a, b) {
      int result;
      switch (filter.sortOption) {
        case SubTaskSortOption.priority:
          result = b.priority.compareTo(a.priority);
        case SubTaskSortOption.dueDate:
          if (a.dueDate == null && b.dueDate == null) {
            result = 0;
          } else if (a.dueDate == null) {
            result = 1;
          } else if (b.dueDate == null) {
            result = -1;
          } else {
            result = a.dueDate!.compareTo(b.dueDate!);
          }
        case SubTaskSortOption.sortOrder:
          result = a.sortOrder.compareTo(b.sortOrder);
      }
      return filter.sortAscending ? result : -result;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'サブタスク',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                style:
                    const TextStyle(color: AppTheme.textTertiary, fontSize: 14),
              ),
              const Spacer(),
              // Subtask filter/sort
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: AppTheme.textSecondary, size: 20),
                color: const Color(0xFF2E2E3E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  final notifier = ref.read(subtaskFilterProvider.notifier);
                  switch (value) {
                    case 'sort_order':
                      notifier.state = filter.copyWith(
                          sortOption: SubTaskSortOption.sortOrder);
                    case 'sort_priority':
                      notifier.state = filter.copyWith(
                          sortOption: SubTaskSortOption.priority);
                    case 'sort_due':
                      notifier.state = filter.copyWith(
                          sortOption: SubTaskSortOption.dueDate);
                    case 'clear_filter':
                      notifier.state = const SubTaskFilterState();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'sort_order',
                      child: Text('カスタム順',
                          style: TextStyle(color: AppTheme.textPrimary))),
                  const PopupMenuItem(
                      value: 'sort_priority',
                      child: Text('優先度順',
                          style: TextStyle(color: AppTheme.textPrimary))),
                  const PopupMenuItem(
                      value: 'sort_due',
                      child: Text('期限順',
                          style: TextStyle(color: AppTheme.textPrimary))),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                      value: 'clear_filter',
                      child: Text('フィルターをクリア',
                          style: TextStyle(color: AppTheme.textSecondary))),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: AppTheme.primaryColor),
                onPressed: () => _addSubTask(task),
              ),
            ],
          ),
        ),
        if (task.subtasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: task.completionRate,
                backgroundColor: AppTheme.glassWhite,
                color: AppTheme.accentGreen,
                minHeight: 4,
              ),
            ),
          ),
        const SizedBox(height: 8),
        // Subtask list
        if (filter.sortOption == SubTaskSortOption.sortOrder)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subtasks.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final reordered = List<SubTask>.from(subtasks);
              final item = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, item);
              final updated = reordered.asMap().entries.map((e) {
                return e.value.copyWith(sortOrder: e.key);
              }).toList();
              ref.read(taskListProvider.notifier).reorderSubTasks(updated);
            },
            proxyDecorator: (child, index, animation) =>
                Material(color: Colors.transparent, child: child),
            itemBuilder: (context, index) {
              return _SubTaskTile(
                key: ValueKey(subtasks[index].id),
                subtask: subtasks[index],
                parentDueDate: task.dueDate,
                allTags: allTags,
              );
            },
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subtasks.length,
            itemBuilder: (context, index) {
              return _SubTaskTile(
                subtask: subtasks[index],
                parentDueDate: task.dueDate,
                allTags: allTags,
              );
            },
          ),
      ],
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: Color(0xFF1E1E2E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _pickEstimatedTime() async {
    final controller = TextEditingController(
      text: _estimatedMinutes?.toString() ?? '',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('見込み時間（分）'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: '例: 60',
            suffixText: '分',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('設定'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _estimatedMinutes = result);
    }
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: Color(0xFF1E1E2E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: Color(0xFF1E1E2E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _showTagPicker(AsyncValue<List<Tag>> allTagsAsync) {
    final allTags = allTagsAsync.valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'タグを選択',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (allTags.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'タグがありません。メニューからタグを作成してください。',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allTags.map((tag) {
                        final isSelected =
                            _selectedTags.any((t) => t.id == tag.id);
                        return TagChip(
                          tag: tag,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedTags.removeWhere((t) => t.id == tag.id);
                              } else {
                                _selectedTags.add(tag);
                              }
                            });
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タスク名を入力してください')),
      );
      return;
    }

    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    try {
      if (_isNew) {
        final task = Task(
          id: _uuid.v4(),
          userId: userId,
          title: title,
          description:
              _descController.text.isEmpty ? null : _descController.text,
          dueDate: _dueDate,
          estimatedMinutes: _estimatedMinutes,
          priority: _priority,
          reminderAt: _reminderAt,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: _selectedTags,
        );
        await ref.read(taskListProvider.notifier).addTask(task);

        // Schedule notification if reminder is set
        if (_reminderAt != null && !kIsWeb) {
          await NotificationService().scheduleReminder(
            id: task.id.hashCode,
            title: 'タスクリマインダー',
            body: title,
            scheduledDate: _reminderAt!,
          );
        }
      } else {
        final updated = _task!.copyWith(
          title: title,
          description:
              _descController.text.isEmpty ? null : _descController.text,
          clearDescription: _descController.text.isEmpty,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          estimatedMinutes: _estimatedMinutes,
          clearEstimatedMinutes: _estimatedMinutes == null,
          priority: _priority,
          reminderAt: _reminderAt,
          clearReminderAt: _reminderAt == null,
          tags: _selectedTags,
        );
        await ref.read(taskListProvider.notifier).updateTask(updated);

        // Update notification
        if (!kIsWeb) {
          await NotificationService().cancelReminder(_task!.id.hashCode);
          if (_reminderAt != null) {
            await NotificationService().scheduleReminder(
              id: _task!.id.hashCode,
              title: 'タスクリマインダー',
              body: title,
              scheduledDate: _reminderAt!,
            );
          }
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを削除'),
        content: const Text('このタスクとすべてのサブタスクが削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除',
                style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(taskListProvider.notifier).deleteTask(widget.taskId!);
      if (!kIsWeb) {
        await NotificationService().cancelReminder(widget.taskId.hashCode);
      }
      if (mounted) context.pop();
    }
  }

  Future<void> _addSubTask(Task task) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サブタスクを追加'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'サブタスク名...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('追加'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      final subtask = SubTask(
        id: _uuid.v4(),
        taskId: task.id,
        userId: userId,
        title: result.trim(),
        sortOrder: task.subtasks.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.read(taskListProvider.notifier).addSubTask(subtask);
    }
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '${hours}時間${mins}分';
    if (hours > 0) return '${hours}時間';
    return '${mins}分';
  }
}

class _SubTaskTile extends ConsumerWidget {
  final SubTask subtask;
  final DateTime? parentDueDate;
  final AsyncValue<List<Tag>> allTags;

  const _SubTaskTile({
    super.key,
    required this.subtask,
    this.parentDueDate,
    required this.allTags,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Drag handle
          const Icon(Icons.drag_indicator,
              size: 18, color: AppTheme.textTertiary),
          const SizedBox(width: 8),
          // Checkbox
          GestureDetector(
            onTap: () => ref
                .read(taskListProvider.notifier)
                .toggleSubTaskComplete(subtask),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: subtask.isCompleted
                      ? AppTheme.accentGreen
                      : AppTheme.glassBorder,
                  width: 1.5,
                ),
                color: subtask.isCompleted
                    ? AppTheme.accentGreen.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
              child: subtask.isCompleted
                  ? const Icon(Icons.check,
                      size: 14, color: AppTheme.accentGreen)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          // Title and meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtask.title,
                  style: TextStyle(
                    color: subtask.isCompleted
                        ? AppTheme.textTertiary
                        : AppTheme.textPrimary,
                    fontSize: 14,
                    decoration: subtask.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (subtask.dueDate != null || subtask.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        if (subtask.dueDate != null) ...[
                          Icon(Icons.calendar_today,
                              size: 11,
                              color: subtask.dueDate!
                                      .isBefore(DateTime.now())
                                  ? AppTheme.accentRed
                                  : AppTheme.textTertiary),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('M/d').format(subtask.dueDate!),
                            style: TextStyle(
                              fontSize: 11,
                              color: subtask.dueDate!
                                      .isBefore(DateTime.now())
                                  ? AppTheme.accentRed
                                  : AppTheme.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ...subtask.tags.map((tag) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: TagChip(tag: tag, isSmall: true),
                            )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          PriorityIndicator(priority: subtask.priority, size: 10),
          const SizedBox(width: 4),
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit, size: 16, color: AppTheme.textTertiary),
            constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: () =>
                _editSubTask(context, ref, subtask, parentDueDate, allTags),
          ),
          // Delete button
          IconButton(
            icon:
                const Icon(Icons.close, size: 16, color: AppTheme.textTertiary),
            constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: () =>
                ref.read(taskListProvider.notifier).deleteSubTask(subtask.id),
          ),
        ],
      ),
    );
  }

  void _editSubTask(
    BuildContext context,
    WidgetRef ref,
    SubTask subtask,
    DateTime? parentDueDate,
    AsyncValue<List<Tag>> allTagsAsync,
  ) {
    final titleController = TextEditingController(text: subtask.title);
    int priority = subtask.priority;
    DateTime? dueDate = subtask.dueDate;
    List<Tag> selectedTags = List.from(subtask.tags);
    final allTags = allTagsAsync.valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'サブタスクを編集',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'タスク名'),
                  ),
                  const SizedBox(height: 16),
                  // Priority
                  Row(
                    children: [
                      const Text('優先度: ',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      ...List.generate(4, (i) {
                        return GestureDetector(
                          onTap: () => setModalState(() => priority = i),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: priority == i
                                  ? AppTheme.getPriorityColor(i)
                                      .withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: priority == i
                                    ? AppTheme.getPriorityColor(i)
                                    : AppTheme.glassBorder,
                              ),
                            ),
                            child: Text(
                              ['なし', '低', '中', '高'][i],
                              style: TextStyle(
                                color: priority == i
                                    ? AppTheme.getPriorityColor(i)
                                    : AppTheme.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Due date
                  Row(
                    children: [
                      const Text('期限: ',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: parentDueDate ??
                                DateTime.now()
                                    .add(const Duration(days: 365 * 5)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppTheme.primaryColor,
                                    surface: Color(0xFF1E1E2E),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setModalState(() => dueDate = date);
                          }
                        },
                        child: Text(
                          dueDate != null
                              ? DateFormat('yyyy/MM/dd').format(dueDate!)
                              : '未設定',
                          style: const TextStyle(color: AppTheme.primaryLight),
                        ),
                      ),
                      if (dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 16, color: AppTheme.textTertiary),
                          onPressed: () =>
                              setModalState(() => dueDate = null),
                        ),
                    ],
                  ),
                  // Tags
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: allTags.map((tag) {
                      final isSelected =
                          selectedTags.any((t) => t.id == tag.id);
                      return TagChip(
                        tag: tag,
                        isSelected: isSelected,
                        isSmall: true,
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              selectedTags.removeWhere((t) => t.id == tag.id);
                            } else {
                              selectedTags.add(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final updated = subtask.copyWith(
                          title: titleController.text.trim(),
                          priority: priority,
                          dueDate: dueDate,
                          clearDueDate: dueDate == null,
                          tags: selectedTags,
                        );
                        ref
                            .read(taskListProvider.notifier)
                            .updateSubTask(updated);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
