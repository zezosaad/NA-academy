import React, { useCallback, useState } from 'react';
import { View, FlatList, Text, StyleSheet, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { useFocusEffect } from '@react-navigation/native';
import { ExamsService } from '../../../services/exams.service';
import { Exam } from '../../../types/exam';
import ExamCard from '../../../components/ExamCard';
import EmptyState from '../../../components/EmptyState';
import { colors, sizes } from '../../../constants/helpers';

export default function ExamsListScreen() {
  const [exams, setExams] = useState<Exam[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchExams = useCallback(async (isRefresh = false) => {
    try {
      if (isRefresh) setRefreshing(true);
      const response = await ExamsService.getAll({ page: 1, limit: 50 });
      setExams(response.data || []);
    } catch (error) {
      console.error('Failed to fetch exams', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useFocusEffect(
    useCallback(() => {
      fetchExams();
    }, [fetchExams])
  );

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Exams</Text>
        <Text style={styles.subtitle}>Test your knowledge in different subjects</Text>
      </View>

      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.primary} />
        </View>
      ) : (
        <FlatList
          data={exams}
          keyExtractor={(item) => item._id}
          renderItem={({ item }) => (
            <ExamCard
              exam={item}
              onPress={() => router.push(`/(tabs)/exams/${item._id}`)}
            />
          )}
          contentContainerStyle={styles.list}
          onRefresh={() => fetchExams(true)}
          refreshing={refreshing}
          ListEmptyComponent={
            <EmptyState
              icon="document-text-outline"
              title="No exams"
              subtitle="No available exams found currently"
            />
          }
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  header: {
    padding: sizes.lg,
    paddingBottom: sizes.sm,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.textPrimary,
  },
  subtitle: {
    fontSize: 14,
    color: colors.textSecondary,
    marginTop: 4,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  list: {
    paddingHorizontal: sizes.lg,
    paddingBottom: sizes.xxxl,
  },
});
