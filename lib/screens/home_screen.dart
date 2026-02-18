import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/tag_provider.dart';
import '../theme/app_theme.dart';
import '../utils/excel_export.dart';
import '../widgets/glass_card.dart';
import '../widgets/priority_indicator.dart';
import '../widgets/tag_chip.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final filteredTasks = ref.watch(filteredTaskListProvider);
    final filter = ref.watch(taskFilterProvider);
    final tags = ref.watch(tagListProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, filter),
              if (_showFilters) _buildFilterBar(filter, tags),
              Expanded(
                child: filteredTasks.when(
                  data: (tasks) => tasks.isEmpty
                      ? _buildEmptyState()
                      : _buildTaskList(tasks),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.accentRed, size: 48),
                        const SizedBox(height: 16),
                        Text('エラーが発生しました',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(e.toString(),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/task/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, TaskFilterState filter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'マイタスク',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Text(
                  DateFormat('yyyy年M月d日(E)', 'ja').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Search
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textPrimary),
            onPressed: () => _showSearchDialog(context),
          ),
          // Filter toggle
          IconButton(
            icon: Icon(
              Icons.tune,
              color: _showFilters
                  ? AppTheme.primaryColor
                  : AppTheme.textPrimary,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          // More menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
            color: const Color(0xFF2E2E3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'export':
                  await _exportToExcel();
                case 'tags':
                  if (context.mounted) context.push('/tags');
                case 'logout':
                  await ref.read(supabaseServiceProvider).signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: AppTheme.textSecondary),
                    SizedBox(width: 12),
                    Text('Excelエクスポート',
                        style: TextStyle(color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'tags',
                child: Row(
                  children: [
                    Icon(Icons.label_outline, color: AppTheme.textSecondary),
                    SizedBox(width: 12),
                    Text('タグ管理',
                        style: TextStyle(color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.accentRed),
                    SizedBox(width: 12),
                    Text('ログアウト',
                        style: TextStyle(color: AppTheme.accentRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(TaskFilterState filter, AsyncValue<dynamic> tags) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort options
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('並べ替え: ',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                _buildSortChip('カスタム', TaskSortOption.sortOrder, filter),
                const SizedBox(width: 4),
                _buildSortChip('優先度', TaskSortOption.priority, filter),
                const SizedBox(width: 4),
                _buildSortChip('期限', TaskSortOption.dueDate, filter),
                const SizedBox(width: 4),
                _buildSortChip('作成日', TaskSortOption.createdAt, filter),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Filter options
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('完了済み表示'),
                  selected: filter.showCompleted,
                  onSelected: (v) => ref
                      .read(taskFilterProvider.notifier)
                      .state = filter.copyWith(showCompleted: v),
                  selectedColor:
                      AppTheme.primaryColor.withValues(alpha: 0.3),
                  checkmarkColor: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                ...['なし', '低', '中', '高'].asMap().entries.map((entry) {
                  final isSelected = filter.priorityFilter == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FilterChip(
                      label: Text(
                        '${entry.value}優先',
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.getPriorityColor(entry.key)
                              : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (v) {
                        ref.read(taskFilterProvider.notifier).state =
                            v
                                ? filter.copyWith(priorityFilter: entry.key)
                                : filter.copyWith(clearPriorityFilter: true);
                      },
                      selectedColor: AppTheme.getPriorityColor(entry.key)
                          .withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.getPriorityColor(entry.key),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(
      String label, TaskSortOption option, TaskFilterState filter) {
    final isSelected = filter.sortOption == option;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          if (isSelected)
            Icon(
              filter.sortAscending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
              color: AppTheme.primaryColor,
            ),
        ],
      ),
      selected: isSelected,
      onSelected: (v) {
        if (isSelected) {
          ref.read(taskFilterProvider.notifier).state =
              filter.copyWith(sortAscending: !filter.sortAscending);
        } else {
          ref.read(taskFilterProvider.notifier).state =
              filter.copyWith(sortOption: option, sortAscending: true);
        }
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'タスクがありません',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '右下の＋ボタンからタスクを追加しましょう',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    final filter = ref.read(taskFilterProvider);
    final isDraggable = filter.sortOption == TaskSortOption.sortOrder;

    if (isDraggable) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: tasks.length,
        onReorder: (oldIndex, newIndex) {
          final reordered = List<Task>.from(tasks);
          if (newIndex > oldIndex) newIndex--;
          final item = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, item);
          final updatedTasks = reordered.asMap().entries.map((e) {
            return e.value.copyWith(sortOrder: e.key);
          }).toList();
          ref.read(taskListProvider.notifier).reorderTasks(updatedTasks);
        },
        proxyDecorator: (child, index, animation) {
          return Material(
            color: Colors.transparent,
            child: child,
          );
        },
        itemBuilder: (context, index) {
          return _TaskCard(
            key: ValueKey(tasks[index].id),
            task: tasks[index],
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _TaskCard(task: tasks[index]);
      },
    );
  }

  void _showSearchDialog(BuildContext context) {
    final controller = TextEditingController(
      text: ref.read(taskFilterProvider).searchQuery,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを検索'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'キーワードを入力...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            ref.read(taskFilterProvider.notifier).state =
                ref.read(taskFilterProvider).copyWith(searchQuery: value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(taskFilterProvider.notifier).state =
                  ref.read(taskFilterProvider).copyWith(searchQuery: '');
              Navigator.pop(context);
            },
            child: const Text('クリア'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskFilterProvider.notifier).state = ref
                  .read(taskFilterProvider)
                  .copyWith(searchQuery: controller.text);
              Navigator.pop(context);
            },
            child: const Text('検索'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToExcel() async {
    final tasks = ref.read(taskListProvider).valueOrNull ?? [];
    if (tasks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('エクスポートするタスクがありません')),
        );
      }
      return;
    }
    try {
      await ExcelExporter.exportTasks(tasks);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('エクスポートが完了しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポートに失敗しました: $e')),
        );
      }
    }
  }
}

class _TaskCard extends ConsumerWidget {
  final Task task;

  const _TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverdue =
        task.dueDate != null && task.dueDate!.isBefore(DateTime.now());

    return GlassCard(
      onTap: () => context.push('/task/${task.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Completion checkbox
              GestureDetector(
                onTap: () =>
                    ref.read(taskListProvider.notifier).toggleComplete(task),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted
                          ? AppTheme.accentGreen
                          : AppTheme.glassBorder,
                      width: 2,
                    ),
                    color: task.isCompleted
                        ? AppTheme.accentGreen.withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check,
                          size: 16, color: AppTheme.accentGreen)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: task.isCompleted
                        ? AppTheme.textTertiary
                        : AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              // Priority
              PriorityIndicator(priority: task.priority),
            ],
          ),
          // Description snippet
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          // Meta info row
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Row(
              children: [
                // Due date
                if (task.dueDate != null) ...[
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isOverdue && !task.isCompleted
                        ? AppTheme.accentRed
                        : AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('M/d').format(task.dueDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue && !task.isCompleted
                          ? AppTheme.accentRed
                          : AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Estimated time
                if (task.estimatedTimeLabel != null) ...[
                  const Icon(Icons.access_time,
                      size: 14, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    task.estimatedTimeLabel!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textTertiary),
                  ),
                  const SizedBox(width: 12),
                ],
                // Subtask count
                if (task.subtasks.isNotEmpty) ...[
                  const Icon(Icons.subdirectory_arrow_right,
                      size: 14, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textTertiary),
                  ),
                  const SizedBox(width: 8),
                  // Progress bar
                  SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(
                      value: task.completionRate,
                      backgroundColor:
                          AppTheme.glassWhite,
                      color: AppTheme.accentGreen,
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Tags
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: task.tags
                          .map((tag) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: TagChip(tag: tag, isSmall: true),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
