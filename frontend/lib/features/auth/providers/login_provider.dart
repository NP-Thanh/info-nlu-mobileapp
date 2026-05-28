import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/auth_repository.dart';

class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final bool obscurePassword;
  final String? fullName;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.obscurePassword = true,
    this.fullName,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool? obscurePassword,
    String? fullName,
    bool clearError = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      fullName: fullName ?? this.fullName,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthRepository _repo;

  LoginNotifier(this._repo) : super(const LoginState());

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> login(String studentId, String password) async {
    if (studentId.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập mã số sinh viên');
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập mật khẩu');
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repo.login(studentId, password);
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        fullName: data['fullName'] as String?,
      );
    } on DioException catch (e) {
      String msg;

      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        msg = 'Không thể kết nối tới server';
      } else if (e.response != null) {
        msg = e.response?.data?['message'] ?? 'Lỗi server';
      } else {
        msg = 'Có lỗi xảy ra';
      }

      state = state.copyWith(isLoading: false, errorMessage: msg);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể kết nối đến máy chủ',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, isSuccess: false);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref.watch(authRepositoryProvider));
});

final logoutProvider = FutureProvider.autoDispose<void>((ref) async {
  await ref.watch(authRepositoryProvider).logout();
});
