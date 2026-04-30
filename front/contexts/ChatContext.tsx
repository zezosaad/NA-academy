import React, { createContext, useEffect, useRef, useState, useCallback } from 'react';
import { io, Socket } from 'socket.io-client';
import { Platform } from 'react-native';
import { Message, Conversation, SendMessagePayload, MessageStatus, ChatMessageType } from '../types/chat';
import { ChatRestService } from '../services/chat.service';

const FALLBACK_URL = Platform.OS === 'android' ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
const SOCKET_URL = process.env.EXPO_PUBLIC_SOCKET_URL || FALLBACK_URL;

interface ChatContextType {
  socket: Socket | null;
  isConnected: boolean;
  conversations: Conversation[];
  messages: Map<string, Message[]>;
  typingUsers: Set<string>;
  isLoadingConversations: boolean;
  sendMessage: (payload: SendMessagePayload) => void;
  markRead: (conversationId: string, senderId: string) => void;
  setTyping: (recipientId: string, isTyping: boolean) => void;
  loadMessages: (conversationId: string, messages: Message[]) => void;
  fetchMessages: (conversationId: string) => Promise<void>;
  setConversations: React.Dispatch<React.SetStateAction<Conversation[]>>;
}

export const ChatContext = createContext<ChatContextType | undefined>(undefined);

export const ChatProvider = ({ children, token }: { children: React.ReactNode; token: string | null }) => {
  const socketRef = useRef<Socket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [messages, setMessages] = useState<Map<string, Message[]>>(new Map());
  const [typingUsers, setTypingUsers] = useState<Set<string>>(new Set());
  const [isLoadingConversations, setIsLoadingConversations] = useState(false);
  const loadedConversationsRef = useRef(false);

  // Load conversations from REST API on mount
  useEffect(() => {
    if (!token || loadedConversationsRef.current) return;
    loadedConversationsRef.current = true;
    setIsLoadingConversations(true);
    ChatRestService.getConversations()
      .then((convs) => setConversations(convs))
      .catch(() => {/* silently ignore — socket will still work */})
      .finally(() => setIsLoadingConversations(false));
  }, [token]);

  useEffect(() => {
    if (!token) return;

    const socket = io(`${SOCKET_URL}/chat`, {
      auth: { token },
      transports: ['websocket'],
    });

    socketRef.current = socket;

    socket.on('connect', () => setIsConnected(true));
    socket.on('disconnect', () => setIsConnected(false));

    socket.on('new_message', (message: Message) => {
      setMessages((prev) => {
        const updated = new Map(prev);
        const convMessages = updated.get(message.conversationId) || [];
        updated.set(message.conversationId, [...convMessages, message]);
        return updated;
      });

      // Send delivery ack
      socket.emit('delivery_ack', {
        messageId: message._id,
        senderId: message.senderId,
      });
    });

    socket.on('pending_messages', (pending: Message[]) => {
      setMessages((prev) => {
        const updated = new Map(prev);
        for (const msg of pending) {
          const convMessages = updated.get(msg.conversationId) || [];
          convMessages.push(msg);
          updated.set(msg.conversationId, convMessages);
        }
        return updated;
      });
    });

    socket.on('status_update', (data: { messageId: string; status: MessageStatus }) => {
      setMessages((prev) => {
        const updated = new Map(prev);
        for (const [convId, msgs] of updated) {
          const idx = msgs.findIndex((m) => m._id === data.messageId);
          if (idx >= 0) {
            msgs[idx] = { ...msgs[idx], status: data.status };
            updated.set(convId, [...msgs]);
            break;
          }
        }
        return updated;
      });
    });

    socket.on('conversation_read', (data: { conversationId: string }) => {
      setMessages((prev) => {
        const updated = new Map(prev);
        const msgs = updated.get(data.conversationId);
        if (msgs) {
          updated.set(
            data.conversationId,
            msgs.map((m) => ({ ...m, status: MessageStatus.READ }))
          );
        }
        return updated;
      });
    });

    socket.on('typing_indicator', (data: { userId: string; isTyping: boolean }) => {
      setTypingUsers((prev) => {
        const updated = new Set(prev);
        if (data.isTyping) {
          updated.add(data.userId);
        } else {
          updated.delete(data.userId);
        }
        return updated;
      });
    });

    return () => {
      socket.disconnect();
      socketRef.current = null;
    };
  }, [token]);

  const sendMessage = useCallback((payload: SendMessagePayload) => {
    socketRef.current?.emit('send_message', payload);
  }, []);

  const markRead = useCallback((conversationId: string, senderId: string) => {
    socketRef.current?.emit('mark_read', { conversationId, senderId });
  }, []);

  const setTyping = useCallback((recipientId: string, isTyping: boolean) => {
    socketRef.current?.emit('typing', { recipientId, isTyping });
  }, []);

  const loadMessages = useCallback((conversationId: string, msgs: Message[]) => {
    setMessages((prev) => {
      const updated = new Map(prev);
      updated.set(conversationId, msgs);
      return updated;
    });
  }, []);

  const fetchMessages = useCallback(async (conversationId: string) => {
    if (!conversationId || conversationId === '') return;
    try {
      const history = await ChatRestService.getMessages(conversationId);
      setMessages((prev) => {
        const updated = new Map(prev);
        const existing = prev.get(conversationId) || [];
        // Merge: history first, then any socket messages not already in history
        const historyIds = new Set(history.map((m) => m._id));
        const socketOnly = existing.filter((m) => !historyIds.has(m._id));
        updated.set(conversationId, [...history, ...socketOnly]);
        return updated;
      });
    } catch {
      // silently ignore — user will still see socket messages
    }
  }, []);

  return (
    <ChatContext.Provider
      value={{
        socket: socketRef.current,
        isConnected,
        conversations,
        messages,
        typingUsers,
        isLoadingConversations,
        sendMessage,
        markRead,
        setTyping,
        loadMessages,
        fetchMessages,
        setConversations,
      }}
    >
      {children}
    </ChatContext.Provider>
  );
};
