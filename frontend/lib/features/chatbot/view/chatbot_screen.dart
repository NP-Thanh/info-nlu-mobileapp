import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../model/chatbot_model.dart';
import '../providers/chatbot_provider.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen>
    with WidgetsBindingObserver {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showScrollDown = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.read(chatbotProvider.notifier).loadHistory(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // reverse ListView: offset 0 = bottom (newest), maxExtent = top (oldest)
    final dist = _scrollController.position.pixels;
    final show = dist > 150;
    if (show != _showScrollDown) setState(() => _showScrollDown = show);
  }

  // Scroll to newest (bottom of chat = offset 0 in reverse list)
  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _focusNode.unfocus();
    await ref.read(chatbotProvider.notifier).sendMessage(text);
    // reverse ListView nên không cần scroll thủ công
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatbotProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      appBar: _AppBar(
        onRefresh: () => ref.read(chatbotProvider.notifier).loadHistory(),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildBody(state),
                // Scroll down button — giữa phía trên input bar
                if (_showScrollDown)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _ScrollDownFab(onTap: _scrollToBottom),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: state.error != null
                ? _ErrorSnack(key: ValueKey(state.error), message: state.error!)
                : const SizedBox.shrink(),
          ),
          _InputBar(
            controller: _inputController,
            focusNode: _focusNode,
            isSending: state.isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ChatbotState state) {
    if (state.isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
      );
    }
    if (state.messages.isEmpty) {
      return _EmptyState(onSuggestion: (s) {
        _inputController.text = s;
        _send();
      });
    }
    return _MessageList(state: state, scrollController: _scrollController);
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefresh;
  const _AppBar({required this.onRefresh});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.primary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.75)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NLU Assistant',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text('Trợ lý AI học vụ',
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    AppColors.textSecondary.withOpacity(0.8))),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.primary, size: 22),
                onPressed: onRefresh,
                tooltip: 'Tải lại',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final void Function(String) onSuggestion;
  const _EmptyState({required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: AppColors.primary, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Xin chào! Tôi là NLU Assistant',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'Hỏi tôi về điểm số, lịch học, thông tin sinh viên hoặc bất kỳ điều gì liên quan đến học vụ.',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withOpacity(0.85),
                height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Gợi ý câu hỏi',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                  label: 'Điểm học kỳ này',
                  onTap: () => onSuggestion('Điểm học kỳ này của tôi')),
              _Chip(
                  label: 'Lịch học hôm nay',
                  onTap: () => onSuggestion('Lịch học hôm nay')),
              _Chip(
                  label: 'GPA tích lũy',
                  onTap: () => onSuggestion('GPA tích lũy của tôi')),
              _Chip(
                  label: 'Thông tin cá nhân',
                  onTap: () => onSuggestion('Thông tin sinh viên của tôi')),
              _Chip(
                  label: 'Môn nào tôi rớt',
                  onTap: () => onSuggestion('Môn nào tôi rớt')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.25), width: 1.5),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

// ─── Message List ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final ChatbotState state;
  final ScrollController scrollController;
  const _MessageList(
      {required this.state, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    // reverse: true — item index 0 = bottom (newest), cuộn lên để xem cũ hơn
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        if (item.isDateDivider) return _DateDivider(date: item.date!);
        if (item.isTyping) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: _TypingBubble(),
          );
        }
        return _BubblePair(message: item.message!);
      },
    );
  }

  List<_ListItem> _buildItems() {
    // Build theo thứ tự cũ → mới, rồi đảo ngược để reverse ListView hiển thị đúng
    final forward = <_ListItem>[];
    DateTime? lastDate;
    for (final msg in state.messages) {
      final d = DateTime(
          msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
      if (lastDate == null || d != lastDate) {
        forward.add(_ListItem.divider(d));
        lastDate = d;
      }
      forward.add(_ListItem.msg(msg));
    }
    if (state.isSending) forward.add(_ListItem.typing());
    // Đảo ngược: item mới nhất ở index 0 (bottom của reverse list)
    return forward.reversed.toList();
  }
}

class _ListItem {
  final ChatMessage? message;
  final DateTime? date;
  final bool isDateDivider;
  final bool isTyping;
  const _ListItem._(
      {this.message,
      this.date,
      this.isDateDivider = false,
      this.isTyping = false});
  factory _ListItem.msg(ChatMessage m) => _ListItem._(message: m);
  factory _ListItem.divider(DateTime d) =>
      _ListItem._(date: d, isDateDivider: true);
  factory _ListItem.typing() => _ListItem._(isTyping: true);
}

// ─── Date Divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Hôm nay';
    if (d == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: Colors.grey.withOpacity(0.25), height: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1)),
              ],
            ),
            child: Text(_label,
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withOpacity(0.75),
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
              child: Divider(
                  color: Colors.grey.withOpacity(0.25), height: 1)),
        ],
      ),
    );
  }
}

// ─── Bubble Pair ──────────────────────────────────────────────────────────────

class _BubblePair extends StatelessWidget {
  final ChatMessage message;
  const _BubblePair({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          _Bubble(
              text: message.question,
              isUser: true,
              time: message.createdAt,
              isFlagged: message.isFlagged),
          if (message.answer.isNotEmpty) ...[
            const SizedBox(height: 6),
            _Bubble(
                text: message.answer,
                isUser: false,
                time: message.createdAt,
                isFlagged: message.isFlagged),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isFlagged;
  const _Bubble({
    required this.text,
    required this.isUser,
    required this.time,
    required this.isFlagged,
  });

  String get _time {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[_BotAvatar(), const SizedBox(width: 8)],
        Flexible(
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              _buildBubble(),
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(
                    left: isUser ? 0 : 2, right: isUser ? 2 : 0),
                child: Text(_time,
                    style: TextStyle(
                        fontSize: 10,
                        color:
                            AppColors.textSecondary.withOpacity(0.55))),
              ),
            ],
          ),
        ),
        if (isUser) ...[const SizedBox(width: 8), _UserAvatar()],
      ],
    );
  }

  Widget _buildBubble() {
    if (isFlagged) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.do_not_disturb_alt_outlined,
                size: 13,
                color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              isUser
                  ? 'Tin nhắn đã được gỡ bỏ'
                  : 'Phản hồi đã được gỡ bỏ',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 5),
          bottomRight: Radius.circular(isUser ? 5 : 18),
        ),
        boxShadow: [
          BoxShadow(
              color: isUser
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 14,
            color: isUser ? Colors.white : AppColors.textPrimary,
            height: 1.5),
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.smart_toy_outlined,
          color: Colors.white, size: 17),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_rounded,
          color: AppColors.primary, size: 19),
    );
  }
}

// ─── Typing Bubble ────────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _BotAvatar(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = _ctrl.value - i * 0.2;
                final t = phase % 1.0;
                final scale =
                    0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          14, 10, 14, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F5F9),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.18),
                    width: 1.5),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4),
                decoration: InputDecoration(
                  hintText: 'Nhập câu hỏi...',
                  hintStyle: TextStyle(
                      color:
                          AppColors.textSecondary.withOpacity(0.55),
                      fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 11),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(isSending: isSending, onTap: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isSending;
  final VoidCallback onTap;
  const _SendButton({required this.isSending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSending ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: isSending
              ? null
              : LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isSending
              ? AppColors.primary.withOpacity(0.4)
              : null,
          shape: BoxShape.circle,
          boxShadow: isSending
              ? []
              : [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3)),
                ],
        ),
        child: isSending
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.send_rounded,
                color: Colors.white, size: 21),
      ),
    );
  }
}

// ─── Scroll Down FAB ──────────────────────────────────────────────────────────

class _ScrollDownFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ScrollDownFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: const Icon(Icons.keyboard_double_arrow_down_rounded,
            color: AppColors.primary, size: 22),
      ),
    );
  }
}

// ─── Error Snack ──────────────────────────────────────────────────────────────

class _ErrorSnack extends StatelessWidget {
  final String message;
  const _ErrorSnack({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(fontSize: 12, color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
