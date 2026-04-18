import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet, RefreshControl, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import Animated, { FadeInDown } from 'react-native-reanimated';
import { useAuthContext } from '../../contexts/AuthContext';
import { SubjectsService } from '../../services/subjects.service';
import { AnalyticsService } from '../../services/analytics.service';
import { Subject } from '../../types/subject';
import { StudentAnalytics } from '../../types/analytics';
import SubjectCard from '../../components/SubjectCard';
import { colors, sizes, width } from '../../constants/helpers';

export default function HomeScreen() {
  const { user } = useAuthContext();
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [analytics, setAnalytics] = useState<StudentAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchData = async (isRefresh = false) => {
    try {
      if (isRefresh) setRefreshing(true);
      const [subjectsRes, analyticsRes] = await Promise.allSettled([
        SubjectsService.getAll({ page: 1, limit: 5 }),
        AnalyticsService.getMyAnalytics(),
      ]);

      if (subjectsRes.status === 'fulfilled') setSubjects(subjectsRes.value.data);
      if (analyticsRes.status === 'fulfilled') setAnalytics(analyticsRes.value);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const formatWatchTime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    if (hours > 0) return `${hours} hr ${minutes} min`;
    return `${minutes} min`;
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.primary} />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => fetchData(true)} tintColor={colors.primary} />}
        contentContainerStyle={styles.scrollContent}
      >
        {/* Header */}
        <Animated.View entering={FadeInDown.delay(100).duration(600)} style={styles.header}>
          <View>
            <Text style={styles.greeting}>Welcome 👋</Text>
            <Text style={styles.userName}>{user?.name || 'Student'}</Text>
          </View>
          <TouchableOpacity style={styles.activateButton} onPress={() => router.push('/(tabs)/profile/activate')}>
            <Ionicons name="key-outline" size={20} color={colors.primary} />
          </TouchableOpacity>
        </Animated.View>

        {/* Quick Stats */}
        <Animated.View entering={FadeInDown.delay(200).duration(600)} style={styles.statsRow}>
          <View style={[styles.statCard, { backgroundColor: `${colors.primary}10` }]}>
            <Ionicons name="time-outline" size={24} color={colors.primary} />
            <Text style={styles.statValue}>
              {analytics ? formatWatchTime(analytics.totalWatchTimeSeconds) : '0 min'}
            </Text>
            <Text style={styles.statLabel}>Watch Time</Text>
          </View>
          <View style={[styles.statCard, { backgroundColor: `${colors.success}10` }]}>
            <Ionicons name="checkmark-circle-outline" size={24} color={colors.success} />
            <Text style={styles.statValue}>{analytics?.totalExamsCompleted || 0}</Text>
            <Text style={styles.statLabel}>Completed Exams</Text>
          </View>
          <View style={[styles.statCard, { backgroundColor: `${colors.warning}10` }]}>
            <Ionicons name="trophy-outline" size={24} color={colors.warning} />
            <Text style={styles.statValue}>{analytics?.averageScore ? `${Math.round(analytics.averageScore)}%` : '-'}</Text>
            <Text style={styles.statLabel}>Avg Score</Text>
          </View>
        </Animated.View>

        {/* Quick Activate */}
        <Animated.View entering={FadeInDown.delay(300).duration(600)}>
          <TouchableOpacity style={styles.activateBanner} onPress={() => router.push('/(tabs)/profile/activate')}>
            <View style={styles.activateBannerIcon}>
              <Ionicons name="gift" size={24} color="#fff" />
            </View>
            <View style={styles.activateBannerText}>
              <Text style={styles.activateBannerTitle}>Enter Activation Code</Text>
              <Text style={styles.activateBannerSubtitle}>Activate your subjects and exams now</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color="#fff" />
          </TouchableOpacity>
        </Animated.View>

        {/* Subjects */}
        <Animated.View entering={FadeInDown.delay(400).duration(600)} style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Available Subjects</Text>
            <TouchableOpacity onPress={() => router.push('/(tabs)/subjects')}>
              <Text style={styles.seeAll}>See All</Text>
            </TouchableOpacity>
          </View>
          {subjects.length === 0 ? (
            <Text style={styles.emptyText}>No subjects available currently</Text>
          ) : (
            subjects.map((subject) => (
              <SubjectCard
                key={subject._id}
                subject={subject}
                onPress={() => router.push(`/(tabs)/subjects/${subject._id}`)}
              />
            ))
          )}
        </Animated.View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scrollContent: {
    padding: sizes.lg,
    paddingBottom: sizes.xxxl,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: sizes.lg,
  },
  greeting: {
    fontSize: 14,
    color: colors.textSecondary,
  },
  userName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.textPrimary,
    marginTop: 2,
  },
  activateButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: `${colors.primary}12`,
    justifyContent: 'center',
    alignItems: 'center',
  },
  statsRow: {
    flexDirection: 'row',
    gap: sizes.sm,
    marginBottom: sizes.lg,
  },
  statCard: {
    flex: 1,
    borderRadius: sizes.sm + 2,
    padding: sizes.sm + 2,
    alignItems: 'center',
    gap: 4,
  },
  statValue: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.textPrimary,
    textAlign: 'center',
  },
  statLabel: {
    fontSize: 11,
    color: colors.textSecondary,
    textAlign: 'center',
  },
  activateBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary,
    borderRadius: sizes.sm + 2,
    padding: sizes.md,
    marginBottom: sizes.lg,
  },
  activateBannerIcon: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: sizes.sm,
  },
  activateBannerText: {
    flex: 1,
  },
  activateBannerTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: '#fff',
  },
  activateBannerSubtitle: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.8)',
    marginTop: 2,
  },
  section: {
    marginBottom: sizes.lg,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: sizes.sm,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.textPrimary,
  },
  seeAll: {
    fontSize: 14,
    color: colors.primary,
    fontWeight: '600',
  },
  emptyText: {
    fontSize: 14,
    color: colors.textSecondary,
    textAlign: 'center',
    paddingVertical: sizes.lg,
  },
});
