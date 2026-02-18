import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../models/subtask.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ============================================
  // Auth
  // ============================================

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ============================================
  // Tags
  // ============================================

  Future<List<Tag>> getTags() async {
    final data = await _client
        .from('tags')
        .select()
        .eq('user_id', _userId)
        .order('name');
    return data.map((json) => Tag.fromJson(json)).toList();
  }

  Future<Tag> createTag(Tag tag) async {
    final data =
        await _client.from('tags').insert(tag.toInsertJson()).select().single();
    return Tag.fromJson(data);
  }

  Future<Tag> updateTag(Tag tag) async {
    final data = await _client
        .from('tags')
        .update({'name': tag.name, 'color': tag.color})
        .eq('id', tag.id)
        .select()
        .single();
    return Tag.fromJson(data);
  }

  Future<void> deleteTag(String tagId) async {
    await _client.from('tags').delete().eq('id', tagId);
  }

  // ============================================
  // Tasks
  // ============================================

  Future<List<Task>> getTasks() async {
    final tasksData = await _client
        .from('tasks')
        .select()
        .eq('user_id', _userId)
        .order('sort_order');

    final tasks = <Task>[];
    for (final taskJson in tasksData) {
      final taskId = taskJson['id'] as String;

      // Fetch tags for this task
      final taskTagsData = await _client
          .from('task_tags')
          .select('tag_id')
          .eq('task_id', taskId);
      final tagIds =
          taskTagsData.map((tt) => tt['tag_id'] as String).toList();

      List<Tag> taskTags = [];
      if (tagIds.isNotEmpty) {
        final tagsData =
            await _client.from('tags').select().inFilter('id', tagIds);
        taskTags = tagsData.map((t) => Tag.fromJson(t)).toList();
      }

      // Fetch subtasks
      final subtasksData = await _client
          .from('subtasks')
          .select()
          .eq('task_id', taskId)
          .order('sort_order');

      final subtasks = <SubTask>[];
      for (final stJson in subtasksData) {
        final stId = stJson['id'] as String;
        final stTagsData = await _client
            .from('subtask_tags')
            .select('tag_id')
            .eq('subtask_id', stId);
        final stTagIds =
            stTagsData.map((st) => st['tag_id'] as String).toList();

        List<Tag> stTags = [];
        if (stTagIds.isNotEmpty) {
          final stTagsFull =
              await _client.from('tags').select().inFilter('id', stTagIds);
          stTags = stTagsFull.map((t) => Tag.fromJson(t)).toList();
        }

        subtasks.add(SubTask.fromJson(stJson, tags: stTags));
      }

      tasks.add(Task.fromJson(taskJson, subtasks: subtasks, tags: taskTags));
    }

    return tasks;
  }

  Future<Task> createTask(Task task) async {
    final data = await _client
        .from('tasks')
        .insert(task.toInsertJson())
        .select()
        .single();

    // Insert tag associations
    if (task.tags.isNotEmpty) {
      await _client.from('task_tags').insert(
            task.tags
                .map((t) => {'task_id': task.id, 'tag_id': t.id})
                .toList(),
          );
    }

    return Task.fromJson(data, subtasks: [], tags: task.tags);
  }

  Future<Task> updateTask(Task task) async {
    final data = await _client
        .from('tasks')
        .update({
          'title': task.title,
          'description': task.description,
          'due_date': task.dueDate?.toIso8601String(),
          'estimated_minutes': task.estimatedMinutes,
          'priority': task.priority,
          'is_completed': task.isCompleted,
          'completed_at': task.completedAt?.toIso8601String(),
          'sort_order': task.sortOrder,
          'reminder_at': task.reminderAt?.toIso8601String(),
        })
        .eq('id', task.id)
        .select()
        .single();

    // Update tag associations
    await _client.from('task_tags').delete().eq('task_id', task.id);
    if (task.tags.isNotEmpty) {
      await _client.from('task_tags').insert(
            task.tags
                .map((t) => {'task_id': task.id, 'tag_id': t.id})
                .toList(),
          );
    }

    return Task.fromJson(data, subtasks: task.subtasks, tags: task.tags);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  Future<void> reorderTasks(List<Task> tasks) async {
    for (int i = 0; i < tasks.length; i++) {
      await _client
          .from('tasks')
          .update({'sort_order': i})
          .eq('id', tasks[i].id);
    }
  }

  // ============================================
  // Subtasks
  // ============================================

  Future<SubTask> createSubTask(SubTask subtask) async {
    final data = await _client
        .from('subtasks')
        .insert(subtask.toInsertJson())
        .select()
        .single();

    if (subtask.tags.isNotEmpty) {
      await _client.from('subtask_tags').insert(
            subtask.tags
                .map((t) => {'subtask_id': subtask.id, 'tag_id': t.id})
                .toList(),
          );
    }

    return SubTask.fromJson(data, tags: subtask.tags);
  }

  Future<SubTask> updateSubTask(SubTask subtask) async {
    final data = await _client
        .from('subtasks')
        .update({
          'title': subtask.title,
          'due_date': subtask.dueDate?.toIso8601String(),
          'priority': subtask.priority,
          'is_completed': subtask.isCompleted,
          'completed_at': subtask.completedAt?.toIso8601String(),
          'sort_order': subtask.sortOrder,
        })
        .eq('id', subtask.id)
        .select()
        .single();

    // Update tag associations
    await _client
        .from('subtask_tags')
        .delete()
        .eq('subtask_id', subtask.id);
    if (subtask.tags.isNotEmpty) {
      await _client.from('subtask_tags').insert(
            subtask.tags
                .map((t) => {'subtask_id': subtask.id, 'tag_id': t.id})
                .toList(),
          );
    }

    return SubTask.fromJson(data, tags: subtask.tags);
  }

  Future<void> deleteSubTask(String subtaskId) async {
    await _client.from('subtasks').delete().eq('id', subtaskId);
  }

  Future<void> reorderSubTasks(List<SubTask> subtasks) async {
    for (int i = 0; i < subtasks.length; i++) {
      await _client
          .from('subtasks')
          .update({'sort_order': i})
          .eq('id', subtasks[i].id);
    }
  }

  // ============================================
  // Realtime
  // ============================================

  RealtimeChannel subscribeToTasks(void Function() onChanged) {
    return _client
        .channel('tasks_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (_) => onChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'subtasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (_) => onChanged(),
        )
        .subscribe();
  }

  void unsubscribe(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }
}
