import '../../../core/storage/storage_manager.dart';
import '../models/story_models.dart';

class StoryCache {
  const StoryCache();

  String get _scope {
    final user = StorageManager.getUserInfo();
    final id = user?['id'] ?? user?['user_id'] ?? user?['phone'];
    return id == null ? 'anonymous' : id.toString();
  }

  String get _listKey => 'story_cache_${_scope}_list_v1';

  String _detailKey(int storyId) => 'story_cache_${_scope}_detail_v1_$storyId';

  List<StoryRecord> getStoryList() {
    final data = StorageManager.getCacheValue(_listKey);
    if (data is! Map) {
      return const [];
    }

    final items = data['items'];
    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map>()
        .map((item) => StoryRecord.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveStoryList(List<StoryRecord> stories) async {
    await StorageManager.saveCacheValue(_listKey, {
      'cached_at': DateTime.now().toIso8601String(),
      'items': stories.map((story) => story.toJson()).toList(),
    });

    for (final story in stories) {
      await saveStory(story);
    }
  }

  StoryRecord? getStory(int storyId) {
    final data = StorageManager.getCacheValue(_detailKey(storyId));
    if (data is! Map) {
      return null;
    }

    final story = data['story'];
    if (story is! Map) {
      return null;
    }

    return StoryRecord.fromJson(Map<String, dynamic>.from(story));
  }

  Future<void> saveStory(StoryRecord story) {
    return StorageManager.saveCacheValue(_detailKey(story.id), {
      'cached_at': DateTime.now().toIso8601String(),
      'story': story.toJson(),
    });
  }

  Future<void> deleteStory(int storyId) async {
    await StorageManager.deleteCacheValue(_detailKey(storyId));

    final stories = getStoryList()
        .where((story) => story.id != storyId)
        .toList(growable: false);
    await StorageManager.saveCacheValue(_listKey, {
      'cached_at': DateTime.now().toIso8601String(),
      'items': stories.map((story) => story.toJson()).toList(),
    });
  }
}
