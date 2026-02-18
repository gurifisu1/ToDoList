import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../models/tag.dart';
import '../providers/auth_provider.dart';
import '../providers/tag_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class TagManagementScreen extends ConsumerWidget {
  const TagManagementScreen({super.key});

  static const _tagColors = [
    '#6C63FF',
    '#FF6B9D',
    '#00D2FF',
    '#00E676',
    '#FF9800',
    '#FF5252',
    '#E040FB',
    '#40C4FF',
    '#FFD740',
    '#69F0AE',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagListProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppTheme.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'タグ管理',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tagsAsync.when(
                  data: (tags) {
                    if (tags.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.label_off,
                                size: 64,
                                color:
                                    AppTheme.primaryColor.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            const Text(
                              'タグがありません',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        return GlassCard(
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: tag.colorValue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tag.name,
                                  style: TextStyle(
                                    color: tag.colorValue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 18, color: AppTheme.textSecondary),
                                onPressed: () =>
                                    _editTag(context, ref, tag),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppTheme.accentRed),
                                onPressed: () =>
                                    _deleteTag(context, ref, tag),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor)),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTag(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addTag(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedColor = _tagColors[0];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('タグを追加'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'タグ名',
                      hintText: '例: 仕事、個人...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tagColors.map((color) {
                      final isSelected = selectedColor == color;
                      final hex = color.replaceFirst('#', '');
                      final colorValue = Color(int.parse('FF$hex', radix: 16));
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorValue,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    final userId = ref.read(currentUserProvider)?.id;
                    if (userId == null) return;

                    final tag = Tag(
                      id: const Uuid().v4(),
                      userId: userId,
                      name: nameController.text.trim(),
                      color: selectedColor,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    ref.read(tagListProvider.notifier).addTag(tag);
                    Navigator.pop(context);
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editTag(BuildContext context, WidgetRef ref, Tag tag) {
    final nameController = TextEditingController(text: tag.name);
    String selectedColor = tag.color;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('タグを編集'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'タグ名'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tagColors.map((color) {
                      final isSelected = selectedColor == color;
                      final hex = color.replaceFirst('#', '');
                      final colorValue = Color(int.parse('FF$hex', radix: 16));
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorValue,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    final updated = tag.copyWith(
                      name: nameController.text.trim(),
                      color: selectedColor,
                    );
                    ref.read(tagListProvider.notifier).updateTag(updated);
                    Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteTag(BuildContext context, WidgetRef ref, Tag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タグを削除'),
        content: Text('「${tag.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(tagListProvider.notifier).deleteTag(tag.id);
              Navigator.pop(context);
            },
            child:
                const Text('削除', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
  }
}
