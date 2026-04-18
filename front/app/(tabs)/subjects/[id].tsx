import React, { useEffect, useState } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { SubjectsService } from '../../../services/subjects.service';
import { MediaService } from '../../../services/media.service';
import { Subject } from '../../../types/subject';
import { MediaAsset, MediaType } from '../../../types/media';
import VideoPlayer from '../../../components/VideoPlayer';
import EmptyState from '../../../components/EmptyState';
import { colors, sizes } from '../../../constants/helpers';

export default function SubjectDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [subject, setSubject] = useState<Subject | null>(null);
  const [mediaAssets, setMediaAssets] = useState<MediaAsset[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeVideoId, setActiveVideoId] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [subjectData, mediaData] = await Promise.all([
          SubjectsService.getById(id),
          MediaService.getBySubjectId(id),
        ]);
        setSubject(subjectData);
        setMediaAssets(mediaData);
      } catch (error) {
        console.error('Failed to fetch subject details', error);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [id]);

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.primary} />
        </View>
      </SafeAreaView>
    );
  }

  if (!subject) {
    return (
      <SafeAreaView style={styles.container}>
        <EmptyState icon="alert-circle-outline" title="Subject not found" />
      </SafeAreaView>
    );
  }

  const formatFileSize = (bytes: number) => {
    if (bytes >= 1_000_000_000) return `${(bytes / 1_000_000_000).toFixed(1)} GB`;
    if (bytes >= 1_000_000) return `${(bytes / 1_000_000).toFixed(1)} MB`;
    return `${(bytes / 1_000).toFixed(1)} KB`;
  };

  const renderMediaItem = ({ item }: { item: MediaAsset }) => {
    if (activeVideoId === item._id) {
      return (
        <View style={styles.videoPlayerContainer}>
          <VideoPlayer
            mediaId={item._id}
            streamUrl={MediaService.getStreamUrl(item._id)}
            title={item.title || item.filename}
            mediaAssetId={item._id}
          />
          <TouchableOpacity style={styles.closeVideo} onPress={() => setActiveVideoId(null)}>
            <Ionicons name="close-circle" size={28} color={colors.danger} />
          </TouchableOpacity>
        </View>
      );
    }

    return (
      <TouchableOpacity
        style={styles.mediaCard}
        onPress={() => {
          if (item.mediaType === MediaType.VIDEO) {
            setActiveVideoId(item._id);
          }
        }}
        activeOpacity={0.7}
      >
        <View style={styles.mediaIcon}>
          <Ionicons
            name={item.mediaType === MediaType.VIDEO ? 'play-circle' : 'image'}
            size={28}
            color={item.mediaType === MediaType.VIDEO ? colors.primary : colors.info}
          />
        </View>
        <View style={styles.mediaInfo}>
          <Text style={styles.mediaTitle} numberOfLines={1}>{item.title || item.filename}</Text>
          <Text style={styles.mediaMeta}>{formatFileSize(item.fileSize)}</Text>
        </View>
        {item.mediaType === MediaType.VIDEO && (
          <Ionicons name="play" size={20} color={colors.primary} />
        )}
      </TouchableOpacity>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <FlatList
        data={mediaAssets}
        keyExtractor={(item) => item._id}
        renderItem={renderMediaItem}
        contentContainerStyle={styles.list}
        ListHeaderComponent={
          <View style={styles.headerSection}>
            <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
              <Ionicons name="arrow-back" size={22} color={colors.textPrimary} />
            </TouchableOpacity>
            <View style={styles.subjectHeader}>
              <View style={styles.subjectIconContainer}>
                <Ionicons name="book" size={36} color={colors.primary} />
              </View>
              <Text style={styles.subjectTitle}>{subject.title}</Text>
              {subject.description && (
                <Text style={styles.subjectDescription}>{subject.description}</Text>
              )}
              <View style={styles.categoryBadge}>
                <Text style={styles.categoryText}>{subject.category}</Text>
              </View>
            </View>
            <Text style={styles.sectionTitle}>
              Content ({mediaAssets.length} files)
            </Text>
          </View>
        }
        ListEmptyComponent={
          <EmptyState icon="videocam-outline" title="No content" subtitle="No files have been added to this subject yet" />
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
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  list: {
    paddingHorizontal: sizes.lg,
    paddingBottom: sizes.xxxl,
  },
  headerSection: {
    paddingBottom: sizes.sm,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.card,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: sizes.md,
    borderWidth: 1,
    borderColor: colors.border,
  },
  subjectHeader: {
    alignItems: 'center',
    marginBottom: sizes.lg,
  },
  subjectIconContainer: {
    width: 72,
    height: 72,
    borderRadius: 20,
    backgroundColor: `${colors.primary}12`,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: sizes.sm,
  },
  subjectTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.textPrimary,
    textAlign: 'center',
    marginBottom: sizes.xs,
  },
  subjectDescription: {
    fontSize: 14,
    color: colors.textSecondary,
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: sizes.sm,
  },
  categoryBadge: {
    backgroundColor: `${colors.primary}15`,
    paddingHorizontal: sizes.sm + 2,
    paddingVertical: 4,
    borderRadius: 8,
  },
  categoryText: {
    fontSize: 13,
    color: colors.primary,
    fontWeight: '600',
  },
  sectionTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: sizes.sm,
  },
  mediaCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: sizes.sm + 2,
    padding: sizes.md,
    marginBottom: sizes.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
  mediaIcon: {
    width: 48,
    height: 48,
    borderRadius: 12,
    backgroundColor: `${colors.primary}08`,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: sizes.sm + 2,
  },
  mediaInfo: {
    flex: 1,
  },
  mediaTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.textPrimary,
    marginBottom: 2,
  },
  mediaMeta: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  videoPlayerContainer: {
    marginBottom: sizes.sm,
    borderRadius: sizes.sm,
    overflow: 'hidden',
  },
  closeVideo: {
    position: 'absolute',
    top: 8,
    right: 8,
    zIndex: 10,
  },
});
