import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../model/chatbot_model.dart';

class ChatbotRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<ChatMessage>> getHistory() async {
    final response = await _dio.get('/chatbot/history');
    return (response.data as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> sendMessage(String message) async {
    final response = await _dio.post('/chatbot/chat', data: {'message': message});
    return (response.data as Map<String, dynamic>)['answer'] as String;
  }
}
