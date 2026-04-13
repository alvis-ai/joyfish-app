import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story_models.dart';
import '../repository/story_repository.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository();
});

class StoryLibraryState {
  final bool loaded;
  final bool isLoading;
  final List<StoryRecord> items;
  final String? error;

  const StoryLibraryState({
    this.loaded = false,
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  StoryLibraryState copyWith({
    bool? loaded,
    bool? isLoading,
    List<StoryRecord>? items,
    String? error,
    bool clearError = false,
  }) {
    return StoryLibraryState(
      loaded: loaded ?? this.loaded,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class StoryLibraryController extends StateNotifier<StoryLibraryState> {
  StoryLibraryController(this.ref) : super(const StoryLibraryState());

  final Ref ref;

  StoryRepository get _repository => ref.read(storyRepositoryProvider);

  Future<void> loadStories({bool force = false}) async {
    if (state.isLoading || (state.loaded && !force)) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.listStories();
      state = state.copyWith(loaded: true, isLoading: false, items: items);
    } catch (error) {
      state = state.copyWith(loaded: true, isLoading: false, error: error.toString());
    }
  }
}

final storyLibraryControllerProvider =
    StateNotifierProvider<StoryLibraryController, StoryLibraryState>((ref) {
  return StoryLibraryController(ref);
});

final recentStoriesProvider = Provider<List<StoryRecord>>((ref) {
  final items = ref.watch(storyLibraryControllerProvider).items;
  if (items.length <= 3) {
    return items;
  }
  return items.take(3).toList();
});
