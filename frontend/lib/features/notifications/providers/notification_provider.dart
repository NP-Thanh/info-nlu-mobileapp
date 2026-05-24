import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository.dart';
import '../model/notification_model.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((_) => NotificationRepository());

class NotificationListState {
  final List<AppNotification> items;
  final bool loading;
  final String? error;
  final bool unreadOnly;
  final bool selectionMode;
  final Set<int> selectedIds;

  const NotificationListState({
    this.items = const [],
    this.loading = false,
    this.error,
    this.unreadOnly = false,
    this.selectionMode = false,
    this.selectedIds = const {},
  });

  List<AppNotification> get visibleItems =>
      unreadOnly ? items.where((n) => !n.isRead).toList() : items;

  int get unreadCount => items.where((n) => !n.isRead).length;

  bool get allVisibleSelected {
    final visible = visibleItems;
    return visible.isNotEmpty &&
        visible.every((n) => selectedIds.contains(n.id));
  }

  NotificationListState copyWith({
    List<AppNotification>? items,
    bool? loading,
    String? error,
    bool? unreadOnly,
    bool? selectionMode,
    Set<int>? selectedIds,
    bool clearError = false,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      unreadOnly: unreadOnly ?? this.unreadOnly,
      selectionMode: selectionMode ?? this.selectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  NotificationListNotifier(this._repo) : super(const NotificationListState());

  final NotificationRepository _repo;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final items = state.unreadOnly
          ? await _repo.getUnreadNotifications()
          : await _repo.getNotifications();
      state = state.copyWith(items: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final items = await _repo.getNotifications();
      state = state.copyWith(items: items);
    } catch (_) {}
  }

  Future<void> toggleUnreadOnly(bool value) async {
    state = state.copyWith(
      unreadOnly: value,
      selectionMode: false,
      selectedIds: {},
    );
    await load();
  }

  void enterSelectionMode(int id) {
    state = state.copyWith(
      selectionMode: true,
      selectedIds: {id},
    );
  }

  void exitSelectionMode() {
    state = state.copyWith(selectionMode: false, selectedIds: {});
  }

  void toggleSelection(int id) {
    final next = Set<int>.from(state.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    if (next.isEmpty) {
      state = state.copyWith(selectionMode: false, selectedIds: {});
    } else {
      state = state.copyWith(selectedIds: next);
    }
  }

  void selectAllVisible() {
    final ids = state.visibleItems.map((n) => n.id).toSet();
    state = state.copyWith(selectedIds: ids, selectionMode: true);
  }

  void deselectAll() {
    state = state.copyWith(selectedIds: {});
  }

  Future<void> openNotification(AppNotification notification) async {
    if (!notification.isRead) {
      try {
        await _repo.markAsRead(notification.id);
        final updated = state.items
            .map((n) =>
                n.id == notification.id ? n.copyWith(isRead: true) : n)
            .toList();
        state = state.copyWith(items: updated);
      } catch (_) {}
    }
  }

  Future<void> markSelectedAsRead() async {
    final ids = state.selectedIds.toList();
    if (ids.isEmpty) return;
    try {
      await _repo.markAsReadMany(ids);
      final idSet = ids.toSet();
      final updated = state.items
          .map((n) => idSet.contains(n.id) ? n.copyWith(isRead: true) : n)
          .toList();
      state = state.copyWith(
        items: updated,
        selectionMode: false,
        selectedIds: {},
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repo.markAllAsRead();
      final updated =
          state.items.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(items: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _repo.deleteNotification(id);
      final updated = state.items.where((n) => n.id != id).toList();
      final selected = Set<int>.from(state.selectedIds)..remove(id);
      state = state.copyWith(
        items: updated,
        selectedIds: selected,
        selectionMode: selected.isNotEmpty && state.selectionMode,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSelected() async {
    final ids = state.selectedIds.toList();
    if (ids.isEmpty) return;
    try {
      await _repo.deleteNotifications(ids);
      final idSet = ids.toSet();
      final updated = state.items.where((n) => !idSet.contains(n.id)).toList();
      state = state.copyWith(
        items: updated,
        selectionMode: false,
        selectedIds: {},
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, NotificationListState>(
        (ref) {
  return NotificationListNotifier(ref.watch(notificationRepositoryProvider));
});

/// Số thông báo chưa đọc — dùng cho badge trên icon chuông (toàn app).
class NotificationBadgeNotifier extends StateNotifier<int> {
  NotificationBadgeNotifier(this._repo) : super(0);

  final NotificationRepository _repo;

  Future<void> refresh() async {
    try {
      final items = await _repo.getUnreadNotifications();
      state = items.length;
    } catch (_) {}
  }
}

final notificationBadgeProvider =
    StateNotifierProvider<NotificationBadgeNotifier, int>((ref) {
  return NotificationBadgeNotifier(ref.watch(notificationRepositoryProvider));
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationBadgeProvider);
});
