import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import Animated, { FadeInDown } from 'react-native-reanimated';
import { colors, sizes } from '../../../../constants/helpers';

export default function AdminDashboard() {
  const adminCards = [
    {
      title: 'Subjects',
      subtitle: 'Create & Manage Subjects',
      icon: 'book-outline' as const,
      color: colors.primary,
      onPress: () => router.push('/(tabs)/profile/admin/subjects'),
    },
    {
      title: 'Exams',
      subtitle: 'Manage Exam Content',
      icon: 'document-text-outline' as const,
      color: colors.info,
      onPress: () => {}, // TODO
    },
    {
      title: 'Users',
      subtitle: 'Manage Rolls & Status',
      icon: 'people-outline' as const,
      color: colors.success,
      onPress: () => {}, // TODO
    },
    {
      title: 'Access Codes',
      subtitle: 'Generate & Track Codes',
      icon: 'key-outline' as const,
      color: colors.warning,
      onPress: () => {}, // TODO
    },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={22} color={colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Admin Panel</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.sectionTitle}>Management Hub</Text>
        
        <View style={styles.grid}>
          {adminCards.map((card, index) => (
            <Animated.View 
              key={index} 
              entering={FadeInDown.delay(100 * index).duration(600)}
              style={styles.cardContainer}
            >
              <TouchableOpacity style={styles.card} onPress={card.onPress} activeOpacity={0.7}>
                <View style={[styles.cardIcon, { backgroundColor: `${card.color}15` }]}>
                  <Ionicons name={card.icon} size={28} color={card.color} />
                </View>
                <Text style={styles.cardTitle}>{card.title}</Text>
                <Text style={styles.cardSubtitle}>{card.subtitle}</Text>
              </TouchableOpacity>
            </Animated.View>
          ))}
        </View>
      </ScrollView>
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
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: sizes.lg,
    paddingVertical: sizes.sm,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.card,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.textPrimary,
  },
  content: {
    padding: sizes.lg,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: colors.textPrimary,
    marginBottom: sizes.lg,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: sizes.md,
  },
  cardContainer: {
    width: '47%',
  },
  card: {
    backgroundColor: colors.card,
    borderRadius: sizes.md,
    padding: sizes.md,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    height: 160,
    justifyContent: 'center',
  },
  cardIcon: {
    width: 56,
    height: 56,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: sizes.sm,
  },
  cardTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: 4,
  },
  cardSubtitle: {
    fontSize: 11,
    color: colors.textSecondary,
    textAlign: 'center',
  },
});
