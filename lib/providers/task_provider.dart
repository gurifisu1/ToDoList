import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

// Sort options
enum TaskSortOption { sortOrder, priority, dueDate, createdAt }

// Filter state
class TaskFilterState {
  final bool showCompleted;
  final int? priorityFilter;
  final String? tagFilter;
  final String searchQuery;
  final TaskSortOption sortOption;
  final bool sortAscending;

  const TaskFilterState({
    this.showCompleted = true,
    this.priorityFilter,
    this.tagFilter,
    this.searchQuery = '',
    this.sortOption = TaskSortOption.sortOrder,
    this.sortAscending = true,
  });

  TaskFilterState copyWith({
    bool? showCompleted,
    int? priorityFilter,
    bool clearPriorityFilter = false,
    String? tagFilter,
    bool clearTagFilter = false,
    String? searchQuery,
    TaskSortOption? sortOption,
    bool? sortAscending,
  }) {
    return TaskFilterState(
      showCompleted: showCompleted ?? this.showCompleted,
      priorityFilter:
          clearPriorityFilter ? null : (priorityFilter ?? this.priorityFilter),
      tagFilter: clearTagFilter ? null : (tagFilter ?? this.tagFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

final taskFilterProvider =
    StateProvider<TaskFilterState>((ref) => const TaskFilterState());

// Subtask sort/filter
enum SubTaskSortOption { sortOrder, priority, dueDate }

class SubTaskFilterState {
  final int? priorityFilter;
  final String? tagFilter;
  final SubTaskSortOption sortOption;
  final bool sortAscending;

  const SubTaskFilterState({
    this.priorityFilter,
    this.tagFilter,
    this.sortOption = SubTaskSortOption.sortOrder,
    this.sortAscending = true,
  });

  SubTaskFilterState copyWith({
    int? priorityFilter,
    bool clearPriorityFilter = false,
    String? tagFilter,
    bool clearTagFilter = false,
    SubTaskSortOption? sortOption,
    bool? sortAscending,
  }) {
    return SubTaskFilterState(
      priorityFilter:
          clearPriorityFilter ? null : (priorityFilter ?? this.priorityFilter),
      tagFilter: clearTagFilter ? null : (tagFilter ?? this.tagFilter),
      sortOption: sortOption ?? this.sortOption,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

final subtaskFilterProvider =
    StateProvider<SubTaskFilterState>((ref) => const SubTaskFilterState());

// Task list provider
final taskListProvider =
    AsyncNotifierProvider<TaskListNotifier, List<Task>>(TaskListNotifier.new);

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  SupabaseService get _service => ref.read(supabaseServiceProvider);
  RealtimeChannel? _channel;

  @override
  Future<List<Task>> build() async {
    ref.onDispose(() {
      if (_channel != null) {
        _service.unsubscribe(_channel!);
      }
    });

    final tasks = await _service.getTasks();

    // Set up realtime subscription
    _channel = _service.subscribeToTasks(() {
      ref.invalidateSelf();
    });

    return tasks;
  }

  Future<void> addTask(Task task) async {
    await _service.createTask(task);
    ref.invalidateSelf();
  }

  Future<void> updateTask(Task task) async {
    await _service.updateTask(task);
    ref.invalidateSelf();
  }

  Future<void> deleteTask(String taskId) async {
    await _service.deleteTask(taskId);
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(Task task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
      clearCompletedAt: task.isCompleted,
    );
    await _service.updateTask(updated);
    ref.invalidateSelf();
  }

  Future<void> reorderTasks(List<Task> tasks) async {
    state = AsyncData(tasks);
    await _service.reorderTasks(tasks);
  }

  // Subtask operations
  Future<void> addSubTask(SubTask subtask) async {
    await _service.createSubTask(subtask);
    ref.invalidateSelf();
  }

  Future<void> updateSubTask(SubTask subtask) async {
    await _service.updateSubTask(subtask);
    ref.invalidateSelf();
  }

  Future<void> deleteSubTask(String subtaskId) async {
    await _service.deleteSubTask(subtaskId);
    ref.invalidateSelf();
  }

  Future<void> toggleSubTaskComplete(SubTask subtask) async {
    final updated = subtask.copyWith(
      isCompleted: !subtask.isCompleted,
      completedAt: !subtask.isCompleted ? DateTime.now() : null,
      clearCompletedAt: subtask.isCompleted,
    );
    await _service.updateSubTask(updated);
    ref.invalidateSelf();
  }

  Future<void> reorderSubTasks(List<SubTask> subtasks) async {
    await _service.reorderSubTasks(subtasks);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Filtered and sorted tasks
final filteredTaskListProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final filter = ref.watch(taskFilterProvider);

  return tasksAsync.whenData((tasks) {
    var filtered = tasks.toList();

    // Filter by completion
    if (!filter.showCompleted) {
      filtered = filtered.where((t) => !t.isCompleted).toList();
    }

    // Filter by priority
    if (filter.priorityFilter != null) {
      filtered =
          filtered.where((t) => t.priority == filter.priorityFilter).toList();
    }

    // Filter by tag
    if (filter.tagFilter != null) {
      filtered = filtered
          .where((t) => t.tags.any((tag) => tag.id == filter.tagFilter))
          .toList();
    }

    // Search
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      filtered = filtered
          .where((t) =>
              t.title.toLowerCase().contains(query) ||
              (t.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    // Sort
    filtered.sort((a, b) {
      int result;
      switch (filter.sortOption) {
        case TaskSortOption.priority:
          result = b.priority.compareTo(a.priority);
        case TaskSortOption.dueDate:
          if (a.dueDate == null && b.dueDate == null) {
            result = 0;
          } else if (a.dueDate == null) {
            result = 1;
          } else if (b.dueDate == null) {
            result = -1;
          } else {
            result = a.dueDate!.compareTo(b.dueDate!);
          }
        case TaskSortOption.createdAt:
          result = b.createdAt.compareTo(a.createdAt);
        case TaskSortOption.sortOrder:
          result = a.sortOrder.compareTo(b.sortOrder);
      }
      return filter.sortAscending ? result : -result;
    });

    return filtered;
  });
});
