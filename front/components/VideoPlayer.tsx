import React, { useRef, useEffect, useState, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ActivityIndicator } from 'react-native';
import { Video, ResizeMode, AVPlaybackStatus } from 'expo-av';
import { Ionicons } from '@expo/vector-icons';
import { colors, sizes } from '../constants/helpers';
import ProgressBar from './ProgressBar';
import { AnalyticsService } from '../services/analytics.service';
import * as SecureStore from 'expo-secure-store';

interface VideoPlayerProps {
  mediaId: string;
  streamUrl: string;
  title?: string;
  mediaAssetId: string;
}

export default function VideoPlayer({ mediaId, streamUrl, title, mediaAssetId }: VideoPlayerProps) {
  const videoRef = useRef<Video>(null);
  const [status, setStatus] = useState<AVPlaybackStatus | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const watchTimeAccumulator = useRef(0);
  const lastPosition = useRef(0);

  const isPlaying = status?.isLoaded && status.isPlaying;
  const duration = status?.isLoaded ? status.durationMillis || 0 : 0;
  const position = status?.isLoaded ? status.positionMillis || 0 : 0;
  const progress = duration > 0 ? position / duration : 0;

  const formatTime = (ms: number) => {
    const totalSec = Math.floor(ms / 1000);
    const min = Math.floor(totalSec / 60);
    const sec = totalSec % 60;
    return `${min}:${sec.toString().padStart(2, '0')}`;
  };

  const sendWatchTime = useCallback(async () => {
    if (watchTimeAccumulator.current >= 5) {
      try {
        await AnalyticsService.trackWatchTime({
          mediaAssetId,
          durationSeconds: Math.floor(watchTimeAccumulator.current),
        });
      } catch (e) {
        // silently fail
      }
      watchTimeAccumulator.current = 0;
    }
  }, [mediaAssetId]);

  const onPlaybackStatusUpdate = useCallback((newStatus: AVPlaybackStatus) => {
    setStatus(newStatus);
    if (newStatus.isLoaded) {
      setIsLoading(false);
      if (newStatus.isPlaying && newStatus.positionMillis > lastPosition.current) {
        const delta = (newStatus.positionMillis - lastPosition.current) / 1000;
        if (delta > 0 && delta < 5) {
          watchTimeAccumulator.current += delta;
        }
      }
      lastPosition.current = newStatus.positionMillis;
    }
  }, []);

  useEffect(() => {
    const interval = setInterval(sendWatchTime, 30000);
    return () => {
      clearInterval(interval);
      sendWatchTime();
    };
  }, [sendWatchTime]);

  const getHeaders = async () => {
    const token = await SecureStore.getItemAsync('accessToken');
    return token ? { Authorization: `Bearer ${token}` } : {};
  };

  const [headers, setHeaders] = useState<Record<string, string>>({});
  useEffect(() => {
    getHeaders().then(setHeaders);
  }, []);

  return (
    <View style={styles.container}>
      {title && <Text style={styles.title}>{title}</Text>}
      <View style={styles.videoContainer}>
        {headers.Authorization ? (
          <Video
            ref={videoRef}
            source={{ uri: streamUrl, headers }}
            style={styles.video}
            resizeMode={ResizeMode.CONTAIN}
            useNativeControls={false}
            onPlaybackStatusUpdate={onPlaybackStatusUpdate}
            shouldPlay={false}
          />
        ) : null}
        {isLoading && (
          <View style={styles.loadingOverlay}>
            <ActivityIndicator size="large" color={colors.primary} />
          </View>
        )}
      </View>

      <View style={styles.controls}>
        <ProgressBar progress={progress} />
        <View style={styles.timeRow}>
          <Text style={styles.timeText}>{formatTime(position)}</Text>
          <Text style={styles.timeText}>{formatTime(duration)}</Text>
        </View>
        <View style={styles.buttonRow}>
          <TouchableOpacity
            onPress={async () => {
              if (!videoRef.current) return;
              await videoRef.current.setPositionAsync(Math.max(position - 10000, 0));
            }}
          >
            <Ionicons name="play-back" size={28} color={colors.textPrimary} />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.playButton}
            onPress={async () => {
              if (!videoRef.current) return;
              if (isPlaying) {
                await videoRef.current.pauseAsync();
              } else {
                await videoRef.current.playAsync();
              }
            }}
          >
            <Ionicons name={isPlaying ? 'pause' : 'play'} size={32} color="#fff" />
          </TouchableOpacity>

          <TouchableOpacity
            onPress={async () => {
              if (!videoRef.current) return;
              await videoRef.current.setPositionAsync(Math.min(position + 10000, duration));
            }}
          >
            <Ionicons name="play-forward" size={28} color={colors.textPrimary} />
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#000',
    borderRadius: sizes.sm,
    overflow: 'hidden',
  },
  title: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    padding: sizes.sm,
  },
  videoContainer: {
    width: '100%',
    aspectRatio: 16 / 9,
    backgroundColor: '#000',
  },
  video: {
    width: '100%',
    height: '100%',
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0,0,0,0.3)',
  },
  controls: {
    padding: sizes.sm,
    backgroundColor: '#111',
  },
  timeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 4,
  },
  timeText: {
    color: 'rgba(255,255,255,0.6)',
    fontSize: 12,
  },
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: sizes.xxl,
    marginTop: sizes.sm,
    paddingBottom: sizes.xs,
  },
  playButton: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
  },
});
