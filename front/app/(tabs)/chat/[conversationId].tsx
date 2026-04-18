import React, { useState, useRef, useEffect } from 'react';
import { View, Text, TextInput, TouchableOpacity, FlatList, StyleSheet, KeyboardAvoidingView, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useChat } from '../../../hooks/useChat';
import { useAuthContext } from '../../../contexts/AuthContext';
import ChatBubble from '../../../components/ChatBubble';
import { Message, ChatMessageType } from '../../../types/chat';
import { colors, sizes } from '../../../constants/helpers';

export default function ConversationScreen() {
  const { conversationId } = useLocalSearchParams<{ conversationId: string }>();
  const { messages: allMessages, sendMessage, markRead, setTyping, typingUsers, conversations } = useChat();
  const { user } = useAuthContext();
  const [text, setText] = useState('');
  const flatListRef = useRef<FlatList>(null);
  const typingTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const conversationMessages = allMessages.get(conversationId) || [];
  const conversation = conversations.find((c) => c._id === conversationId);
  const otherParticipantId = conversation?.participants.find((p) => p !== user?.id) || '';
  const otherName = conversation?.otherParticipant?.name || 'User';
  const isOtherTyping = typingUsers.has(otherParticipantId);

  useEffect(() => {
    if (conversationId && otherParticipantId) {
      markRead(conversationId, otherParticipantId);
    }
  }, [conversationId, conversationMessages.length]);

  const handleSend = () => {
    if (!text.trim() || !otherParticipantId) return;
    sendMessage({
      recipientId: otherParticipantId,
      text: text.trim(),
      messageType: ChatMessageType.TEXT,
    });
    setText('');
    setTyping(otherParticipantId, false);
  };

  const handleTextChange = (value: string) => {
    setText(value);
    if (otherParticipantId) {
      setTyping(otherParticipantId, true);
      if (typingTimeoutRef.current) clearTimeout(typingTimeoutRef.current);
      typingTimeoutRef.current = setTimeout(() => {
        setTyping(otherParticipantId, false);
      }, 2000);
    }
  };

  const renderMessage = ({ item }: { item: Message }) => (
    <ChatBubble message={item} isOwn={item.senderId === user?.id} />
  );

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Ionicons name="arrow-back" size={22} color={colors.textPrimary} />
        </TouchableOpacity>
        <View style={styles.headerInfo}>
          <View style={styles.headerAvatar}>
            <Text style={styles.headerAvatarText}>{otherName.charAt(0).toUpperCase()}</Text>
          </View>
          <View>
            <Text style={styles.headerName}>{otherName}</Text>
            {isOtherTyping && <Text style={styles.typingText}>typing...</Text>}
          </View>
        </View>
      </View>

      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 0}
      >
        <FlatList
          ref={flatListRef}
          data={conversationMessages}
          keyExtractor={(item) => item._id}
          renderItem={renderMessage}
          contentContainerStyle={styles.messagesList}
          onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: true })}
          inverted={false}
        />

        {/* Input */}
        <View style={styles.inputContainer}>
          <TextInput
            style={styles.input}
            placeholder="Type a message..."
            placeholderTextColor={colors.textSecondary}
            value={text}
            onChangeText={handleTextChange}
            multiline
            maxLength={1000}
            textAlign="right"
          />
          <TouchableOpacity
            style={[styles.sendButton, !text.trim() && styles.sendButtonDisabled]}
            onPress={handleSend}
            disabled={!text.trim()}
          >
            <Ionicons name="send" size={20} color={text.trim() ? '#fff' : colors.textSecondary} />
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  flex: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: sizes.lg,
    paddingVertical: sizes.sm + 2,
    backgroundColor: colors.card,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  backBtn: {
    marginRight: sizes.sm,
  },
  headerInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: sizes.sm,
  },
  headerAvatar: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: `${colors.primary}15`,
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerAvatarText: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.primary,
  },
  headerName: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textPrimary,
  },
  typingText: {
    fontSize: 12,
    color: colors.success,
    fontStyle: 'italic',
  },
  messagesList: {
    padding: sizes.sm,
    paddingBottom: sizes.lg,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    padding: sizes.sm,
    backgroundColor: colors.card,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    gap: sizes.sm,
  },
  input: {
    flex: 1,
    minHeight: 42,
    maxHeight: 100,
    backgroundColor: colors.background,
    borderRadius: 21,
    paddingHorizontal: sizes.md,
    paddingVertical: sizes.sm,
    fontSize: 15,
    color: colors.textPrimary,
    borderWidth: 1,
    borderColor: colors.border,
  },
  sendButton: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
  },
  sendButtonDisabled: {
    backgroundColor: colors.border,
  },
});
