/// Helper để reset toàn bộ Riverpod ProviderScope khi logout.
/// Được gọi từ bất kỳ nơi nào mà không cần import main.dart.
typedef _ResetCallback = void Function();

_ResetCallback? _resetCallback;

/// Đăng ký callback reset — được gọi từ _AppRootState
void registerProviderScopeReset(_ResetCallback callback) {
  _resetCallback = callback;
}

/// Gọi hàm này sau logout để xóa toàn bộ Riverpod state
void resetProviderScope() {
  _resetCallback?.call();
}
