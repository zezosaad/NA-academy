import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/features/chat/data/chat_repository.dart';
import 'package:na_app/features/chat/domain/chat_models.dart';

final chatControllerProvider = Provider<ChatController>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatController(repository: repository);
});

class ChatController {
  final ChatRepository _repository;
  String _currentUserId = '';

  ChatController({required ChatRepository repository}) : _repository = repository;

  String get currentUserId => _currentUserId;

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    _repository.currentUserId = userId;
  }

  void sendTextMessage({required String recipientId, required String text}) {
    _repository.sendMessage(recipientId: recipientId, text: text);
  }

  void sendImageMessage({required String recipientId, required String imageFileId}) {
    _repository.sendMessage(recipientId: recipientId, imageFileId: imageFileId);
  }

  void markConversationRead({required String conversationId, required String senderId}) {
    _repository.markRead(conversationId: conversationId, senderId: senderId);
  }

  void sendTyping({required String recipientId, required bool isTyping}) {
    _repository.sendTyping(recipientId: recipientId, isTyping: isTyping);
  }

  List<PendingMessage> get pendingMessages => _repository.pendingMessages;
}