import React, { useState } from 'react';
import { View, FlatList, TextInput, StyleSheet, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useSubjects } from '../../../hooks/useSubjects';
import SubjectCard from '../../../components/SubjectCard';
import EmptyState from '../../../components/EmptyState';
import { colors, sizes } from '../../../constants/helpers';

export default function SubjectsListScreen() {
  const { subjects, loading, refreshing, hasMore, refresh, loadMore } = useSubjects();
  const [search, setSearch] = useState('');

  const filtered = search
    ? subjects.filter(
        (s) =>
          s.title.toLowerCase().includes(search.toLowerCase()) ||
          s.category.toLowerCase().includes(search.toLowerCase())
      )
    : subjects;

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.searchContainer}>
          <Ionicons name="search" size={18} color={colors.textSecondary} />
          <TextInput
            style={styles.searchInput}
            placeholder="Search for subject..."
            placeholderTextColor={colors.textSecondary}
            value={search}
            onChangeText={setSearch}
            textAlign="right"
          />
        </View>
      </View>

      {loading && subjects.length === 0 ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.primary} />
        </View>
      ) : (
        <FlatList
          data={filtered}
          keyExtractor={(item) => item._id}
          renderItem={({ item }) => (
            <SubjectCard
              subject={item}
              onPress={() => router.push(`/(tabs)/subjects/${item._id}`)}
            />
          )}
          contentContainerStyle={styles.list}
          onRefresh={refresh}
          refreshing={refreshing}
          onEndReached={loadMore}
          onEndReachedThreshold={0.3}
          ListFooterComponent={hasMore && !loading ? <ActivityIndicator style={{ padding: sizes.lg }} color={colors.primary} /> : null}
          ListEmptyComponent={<EmptyState icon="book-outline" title="No Subjects" subtitle="No subjects found currently" />}
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
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: sizes.sm + 2,
    paddingHorizontal: sizes.sm + 2,
    height: 44,
    borderWidth: 1,
    borderColor: colors.border,
    gap: sizes.sm,
  },
  searchInput: {
    flex: 1,
    fontSize: 15,
    color: colors.textPrimary,
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
