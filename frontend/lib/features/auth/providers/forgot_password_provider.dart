import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class ForgotPasswordState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const ForgotPasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final Dio _dio = ApiClient.instance;

  ForgotPasswordNotifier() : super(const ForgotPasswordState());

  Future<void> resetPassword(String studentCode, String dateOfBirth) async {
    if (studentCode.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập mã số sinh viên');
      return;
    }
    if (dateOfBirth.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập ngày sinh');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post('/auth/forgot-password', data: {
        'studentCode': studentCode,
        'dateOfBirth': dateOfBirth,
      });
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Có lỗi xảy ra, vui lòng thử lại';
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

  void reset() {
    state = const ForgotPasswordState();
  }
}

final forgotPasswordProvider =
    StateNotifierProvider.autoDispose<ForgotPasswordNotifier, ForgotPasswordState>(
  (ref) => ForgotPasswordNotifier(),
);
