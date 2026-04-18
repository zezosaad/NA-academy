export enum ChatMessageType {
  TEXT = 'text',
  IMAGE = 'image',
}

export enum MessageStatus {
  SENT = 'sent',
  DELIVERED = 'delivered',
  READ = 'read',
}

export interface Message {
  _id: string;
  conversationId: string;
  senderId: string;
  recipientId: string;
  messageType: ChatMessageType;
  text?: string;
  imageFileId?: string;
  status: MessageStatus;
  createdAt: string;
  updatedAt: string;
}

export interface Conversation {
  _id: string;
  roomId: string;
  participants: string[];
  lastMessageAt: string;
  createdAt: string;
  updatedAt: string;
  // Client-side enriched fields
  lastMessage?: Message;
  unreadCount?: number;
  otherParticipant?: {
    _id: string;
    name: string;
    email: string;
    role: string;
  };
}

export interface SendMessagePayload {
  recipientId: string;
  text?: string;
  imageFileId?: string;
  messageType: ChatMessageType;
}

export interface TypingPayload {
  recipientId: string;
  isTyping: boolean;
}
