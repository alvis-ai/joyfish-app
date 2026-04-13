import '../../../core/network/network_manager.dart';
import '../models/story_models.dart';

class StoryRepository {
  Future<StoryRequestRecord> createStoryRequest({
    required int childId,
    String? titleHint,
    String? scenario,
    String? timeOfDay,
    List<String>? themeTags,
    String language = 'zh',
    String? voiceRole,
  }) {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.post(
        '/stories/requests',
        data: {
          'child_id': childId,
          if (titleHint != null && titleHint.isNotEmpty) 'title_hint': titleHint,
          if (scenario != null && scenario.isNotEmpty) 'scenario': scenario,
          if (timeOfDay != null && timeOfDay.isNotEmpty) 'time_of_day': timeOfDay,
          if (themeTags != null && themeTags.isNotEmpty) 'theme_tags': themeTags,
          'language': language,
          if (voiceRole != null && voiceRole.isNotEmpty)
            'options_json': {
              'tts': {'voice_role': voiceRole},
            },
        },
      ),
      (data) => StoryRequestRecord.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<StoryRequestRecord> getStoryRequest(int requestId) {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.get('/stories/requests/$requestId'),
      (data) => StoryRequestRecord.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<List<StoryRequestRecord>> listStoryRequests({String? status}) {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.get(
        '/stories/requests',
        queryParameters: status == null ? null : {'status': status},
      ),
      (data) {
        final map = Map<String, dynamic>.from(data as Map);
        final items = (map['items'] as List<dynamic>? ?? <dynamic>[]);
        return items
            .map((item) => StoryRequestRecord.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      },
    );
  }

  Future<List<StoryRecord>> listStories() {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.get('/stories/'),
      (data) {
        final map = Map<String, dynamic>.from(data as Map);
        final items = (map['items'] as List<dynamic>? ?? <dynamic>[]);
        return items
            .map((item) => StoryRecord.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      },
    );
  }

  Future<StoryRecord> getStory(int storyId) {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.get('/stories/$storyId'),
      (data) => StoryRecord.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }
}
