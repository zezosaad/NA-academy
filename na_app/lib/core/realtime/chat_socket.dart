import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:na_app/core/storage/secure_token_store.dart';

final chatSocketProvider = Provider<ChatSocket>((ref) {
  return ChatSocket(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000',
    ),
    tokenStore: ref.watch(secureTokenStoreProvider),
  );
});

class ChatSocket {
  final String _baseUrl;
  final SecureTokenStore _tokenStore;
  final Future<bool> Function()? onRefreshToken;
  io.Socket? _socket;

  final _newMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingIndicatorController = StreamController<Map<String, dynamic>>.broadcast();
  final _pendingMessagesController = StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<Map<String, dynamic>> get newMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get statusUpdate => _statusUpdateController.stream;
  Stream<Map<String, dynamic>> get conversationRead => _conversationReadController.stream;
  Stream<Map<String, dynamic>> get typingIndicator => _typingIndicatorController.stream;
  Stream<List<Map<String, dynamic>>> get pendingMessages => _pendingMessagesController.stream;

  bool get isConnected => _socket?.connected ?? false;

  ChatSocket({
    required String baseUrl,
    required SecureTokenStore tokenStore,
    this.onRefreshToken,
  })  : _baseUrl = baseUrl,
        _tokenStore = tokenStore;

  static Map<String, dynamic>? _tryCastMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<Map<String, dynamic>>? _tryCastList(dynamic data) {
    if (data is List) {
      try {
        return data.cast<Map<String, dynamic>>();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> connect() async {
    final token = await _tokenStore.accessToken;
    if (token == null || token.isEmpty) return;

    _socket?.dispose();
    _socket = io.io('$_baseUrl/chat', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.on('new_message', (data) {
      final map = _tryCastMap(data);
      if (map != null) {
        _newMessageController.add(map);
      } else {
        debugPrint('[ChatSocket] Invalid new_message payload: $data');
      }
    });

    _socket!.on('status_update', (data) {
      final map = _tryCastMap(data);
      if (map != null) {
        _statusUpdateController.add(map);
      } else {
        debugPrint('[ChatSocket] Invalid status_update payload: $data');
      }
    });

    _socket!.on('conversation_read', (data) {
      final map = _tryCastMap(data);
      if (map != null) {
        _conversationReadController.add(map);
      } else {
        debugPrint('[ChatSocket] Invalid conversation_read payload: $data');
      }
    });

    _socket!.on('typing_indicator', (data) {
      final map = _tryCastMap(data);
      if (map != null) {
        _typingIndicatorController.add(map);
      } else {
        debugPrint('[ChatSocket] Invalid typing_indicator payload: $data');
      }
    });

    _socket!.on('pending_messages', (data) {
      final list = _tryCastList(data);
      if (list != null) {
        _pendingMessagesController.add(list);
      } else {
        debugPrint('[ChatSocket] Invalid pending_messages payload: $data');
      }
    });

    _socket!.on('connect_error', (_) async {
      await _reconnectWithRefresh();
    });

    _socket!.connect();
  }

  void sendMessage({
    required String recipientId,
    String? text,
    String? imageFileId,
    String messageType = 'text',
    String? clientMessageId,
  }) {
    _socket?.emit('send_message', {
      'recipientId': recipientId,
      if (text != null) 'text': text,
      if (imageFileId != null) 'imageFileId': imageFileId,
      'messageType': messageType,
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
    });
  }

  void markRead({required String conversationId, required String senderId}) {
    _socket?.emit('mark_read', {
      'conversationId': conversationId,
      'senderId': senderId,
    });
  }

  void sendTyping({required String recipientId, required bool isTyping}) {
    _socket?.emit('typing', {
      'recipientId': recipientId,
      'isTyping': isTyping,
    });
  }

  void deliveryAck({required String messageId, required String senderId}) {
    _socket?.emit('delivery_ack', {
      'messageId': messageId,
      'senderId': senderId,
    });
  }

  Future<void> _reconnectWithRefresh() async {
    final refreshToken = await _tokenStore.refreshToken;
    if (refreshToken == null) {
      disconnect();
      return;
    }
    if (onRefreshToken != null) {
      final refreshed = await onRefreshToken!();
      if (!refreshed) {
        disconnect();
        return;
      }
    }
    await connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _newMessageController.close();
    _statusUpdateController.close();
    _conversationReadController.close();
    _typingIndicatorController.close();
    _pendingMessagesController.close();
  }
}
