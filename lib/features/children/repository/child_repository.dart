import '../../../core/network/network_manager.dart';
import '../models/child_profile.dart';

class ChildRepository {
  Future<List<ChildProfile>> listChildren() {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.get('/children/'),
      (data) => ((data as List<dynamic>?) ?? <dynamic>[])
          .map((item) => ChildProfile.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Future<ChildProfile> getChild(int id) {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.get('/children/$id'),
      (data) => ChildProfile.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ChildProfile> createChild({
    required String nickname,
    String? birthdate,
    String? gender,
    Map<String, dynamic>? preferences,
  }) {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.post(
        '/children/',
        data: {
          'nickname': nickname,
          if (birthdate != null && birthdate.isNotEmpty) 'birthdate': birthdate,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
          if (preferences != null) 'preferences': preferences,
        },
      ),
      (data) => ChildProfile.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }
}
