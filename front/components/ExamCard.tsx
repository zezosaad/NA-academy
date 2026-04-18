import React from 'react';
import { TouchableOpacity, Text, View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, sizes } from '../constants/helpers';
import { Exam } from '../types/exam';

interface ExamCardProps {
  exam: Exam;
  onPress: () => void;
}

export default function ExamCard({ exam, onPress }: ExamCardProps) {
  return (
    <TouchableOpacity style={styles.card} onPress={onPress} activeOpacity={0.7}>
      <View style={styles.iconContainer}>
        <Ionicons name="document-text" size={28} color={colors.info} />
      </View>
      <View style={styles.content}>
        <Text style={styles.title} numberOfLines={1}>{exam.title}</Text>
        <Text style={styles.meta}>{exam.questions.length} Questions</Text>
        <View style={styles.footer}>
          {exam.hasFreeSection && (
            <View style={styles.freeBadge}>
              <Ionicons name="gift-outline" size={12} color={colors.success} />
              <Text style={styles.freeBadgeText}>Free Section</Text>
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
    backgroundColor: `${colors.info}12`,
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
  meta: {
    fontSize: 13,
    color: colors.textSecondary,
    marginBottom: sizes.xs,
  },
  footer: {
    flexDirection: 'row',
    gap: sizes.xs,
  },
  freeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: `${colors.success}15`,
    paddingHorizontal: sizes.sm,
    paddingVertical: 2,
    borderRadius: 6,
    gap: 4,
  },
  freeBadgeText: {
    fontSize: 11,
    color: colors.success,
    fontWeight: '500',
  },
});
