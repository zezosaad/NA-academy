import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { colors, sizes } from '../constants/helpers';
import { Message, MessageStatus } from '../types/chat';
import { Ionicons } from '@expo/vector-icons';

interface ChatBubbleProps {
  message: Message;
  isOwn: boolean;
}

export default function ChatBubble({ message, isOwn }: ChatBubbleProps) {
  const getStatusIcon = () => {
    if (!isOwn) return null;
    switch (message.status) {
      case MessageStatus.SENT:
        return <Ionicons name="checkmark" size={14} color={colors.textSecondary} />;
      case MessageStatus.DELIVERED:
        return <Ionicons name="checkmark-done" size={14} color={colors.textSecondary} />;
      case MessageStatus.READ:
        return <Ionicons name="checkmark-done" size={14} color={colors.primary} />;
      default:
        return null;
    }
  };

  const time = new Date(message.createdAt).toLocaleTimeString('ar-EG', {
    hour: '2-digit',
    minute: '2-digit',
  });

  return (
    <View style={[styles.container, isOwn ? styles.ownContainer : styles.otherContainer]}>
      <View style={[styles.bubble, isOwn ? styles.ownBubble : styles.otherBubble]}>
        {message.text && (
          <Text style={[styles.text, isOwn ? styles.ownText : styles.otherText]}>
            {message.text}
          </Text>
        )}
        <View style={styles.meta}>
          <Text style={[styles.time, isOwn && styles.ownTime]}>{time}</Text>
          {getStatusIcon()}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: sizes.sm,
    marginVertical: 2,
  },
  ownContainer: {
    alignItems: 'flex-end',
  },
  otherContainer: {
    alignItems: 'flex-start',
  },
  bubble: {
    maxWidth: '80%',
    paddingHorizontal: sizes.sm + 2,
    paddingVertical: sizes.sm,
    borderRadius: sizes.md,
  },
  ownBubble: {
    backgroundColor: colors.primary,
    borderBottomRightRadius: 4,
  },
  otherBubble: {
    backgroundColor: colors.card,
    borderBottomLeftRadius: 4,
    borderWidth: 1,
    borderColor: colors.border,
  },
  text: {
    fontSize: 15,
    lineHeight: 22,
  },
  ownText: {
    color: '#fff',
  },
  otherText: {
    color: colors.textPrimary,
  },
  meta: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    marginTop: 4,
    gap: 4,
  },
  time: {
    fontSize: 11,
    color: colors.textSecondary,
  },
  ownTime: {
    color: 'rgba(255,255,255,0.7)',
  },
});
