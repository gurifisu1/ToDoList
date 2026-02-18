import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

final tagListProvider =
    AsyncNotifierProvider<TagListNotifier, List<Tag>>(TagListNotifier.new);

class TagListNotifier extends AsyncNotifier<List<Tag>> {
  SupabaseService get _service => ref.read(supabaseServiceProvider);

  @override
  Future<List<Tag>> build() async {
    return await _service.getTags();
  }

  Future<void> addTag(Tag tag) async {
    await _service.createTag(tag);
    ref.invalidateSelf();
  }

  Future<void> updateTag(Tag tag) async {
    await _service.updateTag(tag);
    ref.invalidateSelf();
  }

  Future<void> deleteTag(String tagId) async {
    await _service.deleteTag(tagId);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
