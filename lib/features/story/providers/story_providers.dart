import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
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
      final items = await _repository.listStories(forceRefresh: force);
      state = state.copyWith(loaded: true, isLoading: false, items: items);
    } catch (error) {
      state = state.copyWith(
        loaded: true,
        isLoading: false,
        error: userFacingErrorMessage(error),
      );
    }
  }

  Future<bool> deleteStory(int storyId) async {
    if (state.isLoading) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.deleteStory(storyId);
      final items = state.items
          .where((story) => story.id != storyId)
          .toList(growable: false);
      state = state.copyWith(isLoading: false, loaded: true, items: items);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: userFacingErrorMessage(error),
      );
      return false;
    }
  }
}

final storyLibraryControllerProvider =
    StateNotifierProvider<StoryLibraryController, StoryLibraryState>((ref) {
  return StoryLibraryController(ref);
});

final monthlyStoryCreationCountProvider = FutureProvider<int>((ref) async {
  final requests = await ref.read(storyRepositoryProvider).listStoryRequests();
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month);
  final nextMonthStart = DateTime(now.year, now.month + 1);

  return requests.where((request) {
    final createdAt = request.createdAt;
    return createdAt != null &&
        !createdAt.isBefore(monthStart) &&
        createdAt.isBefore(nextMonthStart);
  }).length;
});

final recentStoriesProvider = Provider<List<StoryRecord>>((ref) {
  final items = ref.watch(storyLibraryControllerProvider).items;
  if (items.length <= 3) {
    return items;
  }
  return items.take(3).toList();
});
