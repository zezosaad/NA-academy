import api from './api';
import { Message, Conversation } from '../types/chat';

export const ChatRestService = {
  getConversations: async (): Promise<Conversation[]> => {
    const response = await api.get('/chat/conversations');
    const data = response.data.conversations || response.data.data || response.data;
    return (data as ConversationApiResponse[]).map(mapApiConversation);
  },

  getMessages: async (conversationId: string, limit = 50, before?: string): Promise<Message[]> => {
    const params: Record<string, unknown> = { limit };
    if (before) params.before = before;
    const response = await api.get(`/chat/conversations/${conversationId}/messages`, { params });
    return response.data.data || response.data;
  },

  getPendingMessages: async (): Promise<Message[]> => {
    const response = await api.get('/chat/pending');
    return response.data.data || response.data;
  },
};

interface ConversationApiResponse {
  id: string;
  virtual?: boolean;
  counterpartyId: string;
  counterpartyName: string;
  counterpartyAvatarUrl?: string | null;
  subjectId?: string;
  subjectTitle?: string;
  lastMessage?: {
    text?: string;
    hasImage?: boolean;
    sentAt: string;
    senderId: string;
    status: string;
  } | null;
  unreadCount?: number;
}

function mapApiConversation(item: ConversationApiResponse): Conversation {
  return {
    _id: item.id,
    roomId: '',
    participants: [item.counterpartyId],
    lastMessageAt: item.lastMessage?.sentAt ?? new Date(0).toISOString(),
    createdAt: item.lastMessage?.sentAt ?? new Date(0).toISOString(),
    updatedAt: item.lastMessage?.sentAt ?? new Date(0).toISOString(),
    lastMessage: item.lastMessage
      ? ({
          _id: '',
          conversationId: item.id,
          senderId: item.lastMessage.senderId,
          recipientId: '',
          messageType: item.lastMessage.hasImage ? ('image' as const) : ('text' as const),
          text: item.lastMessage.text,
          status: item.lastMessage.status as Message['status'],
          createdAt: item.lastMessage.sentAt,
          updatedAt: item.lastMessage.sentAt,
        } as Message)
      : undefined,
    unreadCount: item.unreadCount ?? 0,
    otherParticipant: {
      _id: item.counterpartyId,
      name: item.counterpartyName,
      email: '',
      role: '',
    },
    virtual: item.virtual ?? false,
    subjectId: item.subjectId,
    subjectTitle: item.subjectTitle,
  };
}

