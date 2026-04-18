import React, { useEffect, useState } from 'react';
import { View, FlatList, Text, StyleSheet, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import api from '../../../services/api';
import { Exam } from '../../../types/exam';
import ExamCard from '../../../components/ExamCard';
import EmptyState from '../../../components/EmptyState';
import { colors, sizes } from '../../../constants/helpers';

export default function ExamsListScreen() {
  const [exams, setExams] = useState<Exam[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchExams = async (isRefresh = false) => {
    try {
      if (isRefresh) setRefreshing(true);
      // The backend doesn't have a dedicated list exams endpoint for students,
      // but we can fetch exams through subjects or use a generic approach
      const response = await api.get('/subjects');
      const subjects = response.data.data || response.data;

      // Fetch exams for each subject
      const allExams: Exam[] = [];
      for (const subject of subjects.slice(0, 10)) {
        try {
          const examRes = await api.get(`/exams/${subject._id}`);
          const examData = examRes.data.data || examRes.data;
          if (examData) {
            if (Array.isArray(examData)) {
              allExams.push(...examData);
            } else {
              allExams.push(examData);
            }
          }
        } catch {
          // This subject may not have exams
        }
      }
      setExams(allExams);
    } catch (error) {
      console.error('Failed to fetch exams', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchExams();
  }, []);

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
    textAlign: 'right',
  },
  subtitle: {
    fontSize: 14,
    color: colors.textSecondary,
    marginTop: 4,
    textAlign: 'right',
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
