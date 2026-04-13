import '../../../core/network/network_manager.dart';
import '../models/parent_voice_profile.dart';

class VoiceRepository {
  Future<List<ParentVoiceProfile>> listParentVoices() {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.get('/voices/'),
      (data) {
        final map = Map<String, dynamic>.from(data as Map);
        final items = (map['items'] as List<dynamic>? ?? <dynamic>[]);
        return items
            .map((item) => ParentVoiceProfile.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      },
    );
  }

  Future<ParentVoiceProfile> uploadParentVoice({
    required String role,
    required String displayName,
    required String transcript,
    required String audioBase64,
    required String mimeType,
  }) {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.post(
        '/voices/',
        data: {
          'role': role,
          'display_name': displayName,
          'transcript': transcript,
          'audio_base64': audioBase64,
          'mime_type': mimeType,
        },
      ),
      (data) => ParentVoiceProfile.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }
}
