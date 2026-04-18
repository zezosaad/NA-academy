import React from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useChat } from '../../../hooks/useChat';
import { useAuthContext } from '../../../contexts/AuthContext';
import EmptyState from '../../../components/EmptyState';
import { Conversation } from '../../../types/chat';
import { colors, sizes } from '../../../constants/helpers';

export default function ChatListScreen() {
  const { conversations, messages, isConnected } = useChat();
  const { user } = useAuthContext();

  const getLastMessage = (conv: Conversation) => {
    const convMessages = messages.get(conv._id);
    if (convMessages && convMessages.length > 0) {
      return convMessages[convMessages.length - 1];
    }
    return conv.lastMessage;
  };

  const getUnreadCount = (conv: Conversation) => {
    const convMessages = messages.get(conv._id);
    if (!convMessages || !user) return 0;
    return convMessages.filter(
      (m) => m.senderId !== user.id && m.status !== 'read'
    ).length;
  };

  const getOtherParticipantName = (conv: Conversation) => {
    return conv.otherParticipant?.name || 'User';
  };

  const formatTime = (dateStr: string) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days === 0) {
      return date.toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' });
    } else if (days === 1) {
      return 'Yesterday';
    } else if (days < 7) {
      return date.toLocaleDateString('ar-EG', { weekday: 'short' });
    }
    return date.toLocaleDateString('ar-EG', { month: 'short', day: 'numeric' });
  };

  const renderConversation = ({ item }: { item: Conversation }) => {
    const lastMessage = getLastMessage(item);
    const unreadCount = getUnreadCount(item);
    const name = getOtherParticipantName(item);

    return (
      <TouchableOpacity
        style={styles.conversationCard}
        onPress={() => router.push(`/(tabs)/chat/${item._id}`)}
        activeOpacity={0.7}
      >
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{name.charAt(0).toUpperCase()}</Text>
        </View>
        <View style={styles.conversationContent}>
          <View style={styles.conversationHeader}>
            <Text style={[styles.conversationName, unreadCount > 0 && styles.boldText]}>{name}</Text>
            <Text style={styles.timeText}>
              {lastMessage ? formatTime(lastMessage.createdAt) : formatTime(item.lastMessageAt)}
            </Text>
          </View>
          <View style={styles.conversationFooter}>
            <Text style={[styles.lastMessage, unreadCount > 0 && styles.boldText]} numberOfLines={1}>
              {lastMessage?.text || 'No messages'}
            </Text>
            {unreadCount > 0 && (
              <View style={styles.unreadBadge}>
                <Text style={styles.unreadBadgeText}>{unreadCount}</Text>
              </View>
            )}
          </View>
        </View>
      </TouchableOpacity>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Chats</Text>
        <View style={[styles.connectionDot, isConnected ? styles.connected : styles.disconnected]} />
      </View>

      <FlatList
        data={conversations}
        keyExtractor={(item) => item._id}
        renderItem={renderConversation}
        contentContainerStyle={styles.list}
        ListEmptyComponent={
          <EmptyState
            icon="chatbubbles-outline"
            title="No chats"
            subtitle="Your chats will appear here"
          />
        }
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: sizes.lg,
    paddingBottom: sizes.sm,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.textPrimary,
  },
  connectionDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  connected: {
    backgroundColor: colors.success,
  },
  disconnected: {
    backgroundColor: colors.danger,
  },
  list: {
    paddingHorizontal: sizes.lg,
    paddingBottom: sizes.xxxl,
  },
  conversationCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: sizes.sm + 2,
    padding: sizes.md,
    marginBottom: sizes.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
  avatar: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: `${colors.primary}15`,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: sizes.sm + 2,
  },
  avatarText: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.primary,
  },
  conversationContent: {
    flex: 1,
  },
  conversationHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  conversationName: {
    fontSize: 15,
    fontWeight: '500',
    color: colors.textPrimary,
  },
  boldText: {
    fontWeight: '700',
  },
  timeText: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  conversationFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  lastMessage: {
    flex: 1,
    fontSize: 13,
    color: colors.textSecondary,
    marginRight: sizes.sm,
  },
  unreadBadge: {
    minWidth: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 6,
  },
  unreadBadgeText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#fff',
  },
});
