import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/parent_voice_profile.dart';
import '../repository/voice_repository.dart';

final voiceRepositoryProvider = Provider<VoiceRepository>((ref) {
  return VoiceRepository();
});

class VoiceState {
  final bool loaded;
  final bool isLoading;
  final bool isUploading;
  final List<ParentVoiceProfile> items;
  final String? error;

  const VoiceState({
    this.loaded = false,
    this.isLoading = false,
    this.isUploading = false,
    this.items = const [],
    this.error,
  });

  VoiceState copyWith({
    bool? loaded,
    bool? isLoading,
    bool? isUploading,
    List<ParentVoiceProfile>? items,
    String? error,
    bool clearError = false,
  }) {
    return VoiceState(
      loaded: loaded ?? this.loaded,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      items: items ?? this.items,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class VoiceController extends StateNotifier<VoiceState> {
  VoiceController(this.ref) : super(const VoiceState());

  final Ref ref;

  VoiceRepository get _repository => ref.read(voiceRepositoryProvider);

  Future<void> loadVoices({bool force = false}) async {
    if (state.isLoading || (state.loaded && !force)) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.listParentVoices();
      state = state.copyWith(loaded: true, isLoading: false, items: items);
    } catch (error) {
      state = state.copyWith(loaded: true, isLoading: false, error: error.toString());
    }
  }

  Future<ParentVoiceProfile?> uploadVoice({
    required String role,
    required String displayName,
    required String transcript,
    required String audioBase64,
    required String mimeType,
  }) async {
    state = state.copyWith(isUploading: true, clearError: true);
    try {
      final record = await _repository.uploadParentVoice(
        role: role,
        displayName: displayName,
        transcript: transcript,
        audioBase64: audioBase64,
        mimeType: mimeType,
      );
      final others = state.items.where((item) => item.role != record.role).toList();
      state = state.copyWith(
        loaded: true,
        isUploading: false,
        items: [record, ...others],
      );
      return record;
    } catch (error) {
      state = state.copyWith(isUploading: false, error: error.toString());
      return null;
    }
  }
}

final voiceControllerProvider =
    StateNotifierProvider<VoiceController, VoiceState>((ref) {
  return VoiceController(ref);
});
