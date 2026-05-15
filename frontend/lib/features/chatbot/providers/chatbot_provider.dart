import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chatbot_repository.dart';
import '../model/chatbot_model.dart';

final chatbotRepositoryProvider =
    Provider<ChatbotRepository>((_) => ChatbotRepository());

// State: danh sách tin nhắn + trạng thái đang gửi
class ChatbotState {
  final List<ChatMessage> messages;
  final bool isSending;
  final bool isLoadingHistory;
  final String? error;

  const ChatbotState({
    this.messages = const [],
    this.isSending = false,
    this.isLoadingHistory = false,
    this.error,
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? isLoadingHistory,
    String? error,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error,
    );
  }
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  final ChatbotRepository _repo;

  ChatbotNotifier(this._repo) : super(const ChatbotState()) {
    loadHistory();
  }

  Future<void> loadHistory({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoadingHistory: true, error: null);
    try {
      final history = await _repo.getHistory();
      state = state.copyWith(messages: history, isLoadingHistory: false);
    } catch (e) {
      if (!silent) {
        state = state.copyWith(isLoadingHistory: false, error: e.toString());
      }
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isSending) return;

    // Thêm tin nhắn tạm (optimistic) với answer rỗng để hiện typing
    final tempMsg = ChatMessage(
      question: text.trim(),
      answer: '',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, tempMsg],
      isSending: true,
      error: null,
    );

    try {
      final answer = await _repo.sendMessage(text.trim());
      // Thay tin nhắn tạm bằng tin nhắn thật
      final realMsg = ChatMessage(
        question: text.trim(),
        answer: answer,
        createdAt: DateTime.now(),
      );
      final updated = [...state.messages];
      updated[updated.length - 1] = realMsg;
      state = state.copyWith(messages: updated, isSending: false);
    } catch (e) {
      // Xóa tin nhắn tạm nếu lỗi
      final updated = [...state.messages]..removeLast();
      state = state.copyWith(
        messages: updated,
        isSending: false,
        error: 'Không thể gửi tin nhắn. Vui lòng thử lại.',
      );
    }
  }
}

final chatbotProvider =
    StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  return ChatbotNotifier(ref.read(chatbotRepositoryProvider));
});
