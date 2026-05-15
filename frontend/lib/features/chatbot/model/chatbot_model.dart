class ChatMessage {
  final int? id;
  final String question;
  final String answer;
  final DateTime createdAt;
  final bool isFlagged;

  const ChatMessage({
    this.id,
    required this.question,
    required this.answer,
    required this.createdAt,
    this.isFlagged = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int?,
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isFlagged: json['isFlagged'] == true,
    );
  }
}
