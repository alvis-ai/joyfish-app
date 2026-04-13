import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_manager.dart';
import '../models/child_profile.dart';
import '../repository/child_repository.dart';

final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return ChildRepository();
});

class ChildrenState {
  final bool loaded;
  final bool isLoading;
  final bool isSubmitting;
  final List<ChildProfile> items;
  final int? selectedChildId;
  final String? error;

  const ChildrenState({
    this.loaded = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.items = const [],
    this.selectedChildId,
    this.error,
  });

  ChildProfile? get selectedChild {
    if (selectedChildId == null) {
      return items.isEmpty ? null : items.first;
    }
    for (final child in items) {
      if (child.id == selectedChildId) {
        return child;
      }
    }
    return items.isEmpty ? null : items.first;
  }

  ChildrenState copyWith({
    bool? loaded,
    bool? isLoading,
    bool? isSubmitting,
    List<ChildProfile>? items,
    int? selectedChildId,
    String? error,
    bool clearError = false,
  }) {
    return ChildrenState(
      loaded: loaded ?? this.loaded,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      items: items ?? this.items,
      selectedChildId: selectedChildId ?? this.selectedChildId,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ChildController extends StateNotifier<ChildrenState> {
  ChildController(this.ref) : super(const ChildrenState());

  final Ref ref;

  ChildRepository get _repository => ref.read(childRepositoryProvider);

  Future<void> loadChildren({bool force = false}) async {
    if (state.isLoading || (state.loaded && !force)) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.listChildren();
      final selected = _pickSelectedChild(items);
      if (selected != null) {
        await StorageManager.saveSelectedChild(selected.toJson());
      } else {
        await StorageManager.clearSelectedChild();
      }
      state = state.copyWith(
        loaded: true,
        isLoading: false,
        items: items,
        selectedChildId: selected?.id,
      );
    } catch (error) {
      state = state.copyWith(
        loaded: true,
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> createChild({
    required String nickname,
    String? birthdate,
    String? gender,
    Map<String, dynamic>? preferences,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final child = await _repository.createChild(
        nickname: nickname,
        birthdate: birthdate,
        gender: gender,
        preferences: preferences,
      );
      final items = [child, ...state.items];
      await StorageManager.saveSelectedChild(child.toJson());
      state = state.copyWith(
        loaded: true,
        isSubmitting: false,
        items: items,
        selectedChildId: child.id,
      );
    } catch (error) {
      state = state.copyWith(isSubmitting: false, error: error.toString());
    }
  }

  Future<void> selectChild(ChildProfile child) async {
    await StorageManager.saveSelectedChild(child.toJson());
    state = state.copyWith(selectedChildId: child.id, clearError: true);
  }

  ChildProfile? _pickSelectedChild(List<ChildProfile> items) {
    final cached = StorageManager.getSelectedChild();
    final cachedId = cached?['id'] as int?;
    if (cachedId != null) {
      for (final child in items) {
        if (child.id == cachedId) {
          return child;
        }
      }
    }
    return items.isEmpty ? null : items.first;
  }
}

final childControllerProvider =
    StateNotifierProvider<ChildController, ChildrenState>((ref) {
  return ChildController(ref);
});

final selectedChildProvider = Provider<ChildProfile?>((ref) {
  return ref.watch(childControllerProvider).selectedChild;
});
