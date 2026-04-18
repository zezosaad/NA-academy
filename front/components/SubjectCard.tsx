import React from 'react';
import { TouchableOpacity, Text, View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, sizes } from '../constants/helpers';
import { Subject } from '../types/subject';

interface SubjectCardProps {
  subject: Subject;
  onPress: () => void;
}

export default function SubjectCard({ subject, onPress }: SubjectCardProps) {
  return (
    <TouchableOpacity style={styles.card} onPress={onPress} activeOpacity={0.7}>
      <View style={styles.iconContainer}>
        <Ionicons name="book" size={28} color={colors.primary} />
      </View>
      <View style={styles.content}>
        <Text style={styles.title} numberOfLines={1}>{subject.title}</Text>
        {subject.description ? (
          <Text style={styles.description} numberOfLines={2}>{subject.description}</Text>
        ) : null}
        <View style={styles.footer}>
          <View style={styles.badge}>
            <Text style={styles.badgeText}>{subject.category}</Text>
          </View>
          {!subject.isActive && (
            <View style={[styles.badge, styles.inactiveBadge]}>
              <Text style={[styles.badgeText, styles.inactiveBadgeText]}>Inactive</Text>
            </View>
          )}
        </View>
      </View>
      <Ionicons name="chevron-forward" size={20} color={colors.secondary} />
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: sizes.sm + 2,
    padding: sizes.md,
    marginBottom: sizes.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
  iconContainer: {
    width: 52,
    height: 52,
    borderRadius: 14,
    backgroundColor: `${colors.primary}12`,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: sizes.sm + 2,
  },
  content: {
    flex: 1,
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textPrimary,
    marginBottom: 2,
  },
  description: {
    fontSize: 13,
    color: colors.textSecondary,
    marginBottom: sizes.xs,
    lineHeight: 18,
  },
  footer: {
    flexDirection: 'row',
    gap: sizes.xs,
  },
  badge: {
    backgroundColor: `${colors.primary}15`,
    paddingHorizontal: sizes.sm,
    paddingVertical: 2,
    borderRadius: 6,
  },
  badgeText: {
    fontSize: 11,
    color: colors.primary,
    fontWeight: '500',
  },
  inactiveBadge: {
    backgroundColor: `${colors.warning}20`,
  },
  inactiveBadgeText: {
    color: colors.warning,
  },
});
