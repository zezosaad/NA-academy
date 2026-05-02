import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:na_app/core/api/api_environment.dart';
import 'package:na_app/core/realtime/chat_trace.dart';
import 'package:na_app/core/storage/secure_token_store.dart';

final chatSocketProvider = Provider<ChatSocket>((ref) {
  return ChatSocket(
    baseUrl: socketIoOriginFromApiBaseUrl(kApiBaseUrl),
    tokenStore: ref.watch(secureTokenStoreProvider),
  );
});

class ChatSocket {
  final String _baseUrl;
  final SecureTokenStore _tokenStore;
  final Future<bool> Function()? onRefreshToken;
  io.Socket? _socket;
  final List<Map<String, dynamic>> _pendingOutgoingMessages = [];

  final _newMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _statusUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _conversationReadController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _typingIndicatorController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _pendingMessagesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _chatErrorController = StreamController<String>.broadcast();
  final _messageAckController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _gatewayErrorController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get newMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get statusUpdate =>
      _statusUpdateController.stream;
  Stream<Map<String, dynamic>> get conversationRead =>
      _conversationReadController.stream;
  Stream<Map<String, dynamic>> get typingIndicator =>
      _typingIndicatorController.stream;
  Stream<List<Map<String, dynamic>>> get pendingMessages =>
      _pendingMessagesController.stream;
  Stream<String> get chatErrors => _chatErrorController.stream;
  Stream<Map<String, dynamic>> get messageAck => _messageAckController.stream;
  Stream<Map<String, dynamic>> get gatewayErrors =>
      _gatewayErrorController.stream;

  bool get isConnected => _socket?.connected ?? false;

  ChatSocket({
    required String baseUrl,
    required SecureTokenStore tokenStore,
    this.onRefreshToken,
  }) : _baseUrl = baseUrl,
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
    if (token == null || token.isEmpty) {
      ChatTrace.log('CONNECT_SKIPPED', {'reason': 'no_access_token'});
      return;
    }

    ChatTrace.log('CONNECT_START', {
      'socketUrl': '${_baseUrl}/chat',
      'tokenChars': '${token.length}',
    });

    _socket?.dispose();
    _socket = io.io('$_baseUrl/chat', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
      'timeout': 20000,
    });

    _socket!.on('disconnect', (dynamic reason) {
      ChatTrace.log('SOCKET_DISCONNECTED', {'reason': '$reason'});
    });

    _socket!.on('reconnect', (dynamic attempt) {
      ChatTrace.log('SOCKET_RECONNECT_OK', {'attempt': '$attempt'});
    });

    _socket!.on('reconnect_error', (dynamic err) {
      ChatTrace.log('SOCKET_RECONNECT_ERROR', {'error': '$err'});
    });

    /// NestJS gateway `return { event: 'error', data }` → `socket.emit('error', data)`.
    _socket!.on('error', (dynamic data) {
      ChatTrace.log(
        'SOCKET_GATEWAY_ERROR',
        {'payload': '${data.runtimeType}:$data'},
      );
      final m = _tryCastMap(data);
      if (m != null) {
        _gatewayErrorController.add(m);
      } else if (data is String && data.isNotEmpty) {
        _gatewayErrorController.add({'detail': data});
      } else if (data != null) {
        _gatewayErrorController.add({'detail': data.toString()});
      }
    });

    _socket!.on('message_ack', (dynamic data) {
      final map = _tryCastMap(data);
      if (map != null) {
        _messageAckController.add(map);
        ChatTrace.log(
          'MESSAGE_ACK_RX',
          map.map((k, v) => MapEntry('$k', v)),
        );
      } else {
        ChatTrace.log('MESSAGE_ACK_INVALID', {'data': '${data.runtimeType}:$data'});
      }
    });

    _socket!.on('new_message', (data) {
      ChatTrace.log('NEW_MESSAGE_RAW_TYPE', {'type': '${data.runtimeType}'});
      final map = _tryCastMap(data);
      if (map != null) {
        _newMessageController.add(map);
      } else {
        debugPrint('[ChatSocket] Invalid new_message payload: $data');
        final s = '$data';
        ChatTrace.log('NEW_MESSAGE_REJECTED', {
          'snippet':
              s.length > 240 ? '${s.substring(0, 240)}… (${s.length} chars)' : s,
        });
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

    _socket!.on('unauthorized_conversation', (data) {
      final map = _tryCastMap(data);
      final message =
          map?['message'] as String? ?? 'Unauthorized to chat with this user';
      _chatErrorController.add(message);
    });

    _socket!.on('connect_error', (dynamic err) async {
      ChatTrace.log('SOCKET_CONNECT_ERROR', {'error': '$err'});
      await _reconnectWithRefresh();
    });

    _socket!.on('connect', (_) {
      ChatTrace.log('SOCKET_CONNECTED', {'id': _socket?.id ?? '?'});
      if (_pendingOutgoingMessages.isEmpty) return;
      final queued = List<Map<String, dynamic>>.from(_pendingOutgoingMessages);
      _pendingOutgoingMessages.clear();
      ChatTrace.log(
        'FLUSH_OUTBOUND_QUEUE',
        {'queued': queued.length.toString()},
      );
      for (final payload in queued) {
        _socket?.emit('send_message', payload);
      }
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
    final payload = <String, dynamic>{
      'recipientId': recipientId,
      if (text != null) 'text': text,
      if (imageFileId != null) 'imageFileId': imageFileId,
      'messageType': messageType,
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
    };

    ChatTrace.log('SEND_MESSAGE', {
      'connected': '${_socket?.connected}',
      'socketId': _socket?.id ?? 'null',
      'recipientId': payload['recipientId']?.toString() ?? '',
      'messageType': payload['messageType']?.toString() ?? '',
      'clientMessageId': payload['clientMessageId']?.toString() ?? '',
      'textLen': '${(payload['text'] as String?)?.length ?? 0}',
      'queuedBefore': '${_pendingOutgoingMessages.length}',
    });

    if (_socket?.connected == true) {
      _socket?.emit('send_message', payload);
      return;
    }

    ChatTrace.log('SEND_QUEUE_NOT_CONNECTED', {
      'queueAfter': '${_pendingOutgoingMessages.length + 1}',
    });
    _pendingOutgoingMessages.add(payload);
    unawaited(connect());
  }

  void markRead({required String conversationId, required String senderId}) {
    _socket?.emit('mark_read', {
      'conversationId': conversationId,
      'senderId': senderId,
    });
  }

  void sendTyping({required String recipientId, required bool isTyping}) {
    _socket?.emit('typing', {'recipientId': recipientId, 'isTyping': isTyping});
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
    _chatErrorController.close();
    _messageAckController.close();
    _gatewayErrorController.close();
  }
}
