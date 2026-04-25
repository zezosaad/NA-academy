enum MessageType { text, image }

enum MessageDeliveryStatus { pending, sent, delivered, read, failed, deleted }

class Conversation {
  final String id;
  final bool virtual;
  final String counterpartyId;
  final String counterpartyName;
  final String? counterpartyAvatarUrl;
  final String subjectId;
  final String subjectTitle;
  final MessagePreview? lastMessage;
  final int unreadCount;

  const Conversation({
    required this.id,
    this.virtual = false,
    required this.counterpartyId,
    required this.counterpartyName,
    this.counterpartyAvatarUrl,
    required this.subjectId,
    required this.subjectTitle,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: (json['id'] as String?) ?? '',
      virtual: json['virtual'] as bool? ?? false,
      counterpartyId: json['counterpartyId'] as String,
      counterpartyName: json['counterpartyName'] as String,
      counterpartyAvatarUrl: json['counterpartyAvatarUrl'] as String?,
      subjectId: json['subjectId'] as String,
      subjectTitle: json['subjectTitle'] as String? ?? '',
      lastMessage: json['lastMessage'] != null
          ? MessagePreview.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}

class MessagePreview {
  final String? text;
  final bool hasImage;
  final DateTime sentAt;
  final String senderId;
  final String status;

  const MessagePreview({
    this.text,
    this.hasImage = false,
    required this.sentAt,
    required this.senderId,
    required this.status,
  });

  factory MessagePreview.fromJson(Map<String, dynamic> json) {
    return MessagePreview(
      text: json['text'] as String?,
      hasImage: json['hasImage'] as bool? ?? false,
      sentAt: DateTime.parse(json['sentAt'] as String),
      senderId: json['senderId'] as String,
      status: json['status'] as String? ?? 'sent',
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final MessageType type;
  final String? text;
  final String? imageFileId;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final MessageDeliveryStatus status;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.type,
    this.text,
    this.imageFileId,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.status = MessageDeliveryStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final senderIdRaw = json['senderId'];
    String senderId;
    if (senderIdRaw is String) {
      senderId = senderIdRaw;
    } else if (senderIdRaw is Map) {
      senderId = senderIdRaw['_id'] as String? ?? '';
    } else {
      senderId = '';
    }

    return ChatMessage(
      id: (json['_id'] as String?) ?? json['id'] as String? ?? '',
      conversationId: (json['conversationId'] as String?) ?? '',
      senderId: senderId,
      recipientId: json['recipientId'] as String? ?? '',
      type: _parseMessageType(json['messageType'] as String?),
      text: json['text'] as String?,
      imageFileId: json['imageFileId'] as String?,
      sentAt: _parseDate(json['createdAt'] as String?) ?? DateTime.now(),
      deliveredAt: _parseDate(json['deliveredAt'] as String?),
      readAt: _parseDate(json['readAt'] as String?),
      status: _parseDeliveryStatus(json['status'] as String?),
    );
  }

  static MessageType _parseMessageType(String? value) => switch (value) {
        'image' => MessageType.image,
        _ => MessageType.text,
      };

  static MessageDeliveryStatus _parseDeliveryStatus(String? value) => switch (value) {
        'pending' => MessageDeliveryStatus.pending,
        'delivered' => MessageDeliveryStatus.delivered,
        'read' => MessageDeliveryStatus.read,
        'failed' => MessageDeliveryStatus.failed,
        'deleted' => MessageDeliveryStatus.deleted,
        _ => MessageDeliveryStatus.sent,
      };

  static DateTime? _parseDate(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}

class PendingMessage {
  final String localId;
  final String recipientId;
  final String? text;
  final String? imageFileId;
  final MessageType type;
  final MessageDeliveryStatus status;
  final DateTime createdAt;

  const PendingMessage({
    required this.localId,
    required this.recipientId,
    this.text,
    this.imageFileId,
    required this.type,
    this.status = MessageDeliveryStatus.pending,
    required this.createdAt,
  });
}