import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/auth_repository.dart';

// State cho login
class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final bool obscurePassword;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.obscurePassword = true,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool? obscurePassword,
    bool clearError = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      obscurePassword: obscurePassword ?? this.obscurePassword,
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
    // Validate studentId: chỉ chứa số
    if (studentId.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập mã số sinh viên');
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập mật khẩu');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(studentId)) {
      state = state.copyWith(
        errorMessage: 'Mã số sinh viên chỉ được chứa chữ số',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.login(studentId, password);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Sai mã số sinh viên hoặc mật khẩu';
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
