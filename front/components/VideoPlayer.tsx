import React, { useRef, useEffect, useState, useCallback } from 'react';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';
import { useVideoPlayer, VideoView } from 'expo-video';
import { useEvent } from 'expo';
import { colors, sizes } from '../constants/helpers';
import { AnalyticsService } from '../services/analytics.service';
import * as SecureStore from 'expo-secure-store';
import { normalizeToken } from '../utils/auth-token';

interface VideoPlayerProps {
  mediaId: string;
  streamUrl: string;
  title?: string;
  mediaAssetId: string;
}

export default function VideoPlayer({ mediaId, streamUrl, title, mediaAssetId }: VideoPlayerProps) {
  const watchTimeAccumulator = useRef(0);
  const lastPosition = useRef(0);
  const [videoSource, setVideoSource] = useState<{ uri: string } | null>(null);
  const [playerError, setPlayerError] = useState<string | null>(null);

  useEffect(() => {
    SecureStore.getItemAsync('accessToken').then(token => {
      const normalizedToken = normalizeToken(token);

      if (normalizedToken) {
        setVideoSource({
          uri: `${streamUrl}${streamUrl.includes('?') ? '&' : '?'}token=${encodeURIComponent(normalizedToken)}`,
        });
      } else {
        setPlayerError('Authentication is required to load this video.');
      }
    });
  }, [streamUrl]);

  const player = useVideoPlayer(videoSource, (p) => {
    p.timeUpdateEventInterval = 1;
  });

  const { isPlaying } = useEvent(player, 'playingChange', { isPlaying: player.playing });
  const { currentTime } = useEvent(player, 'timeUpdate', {
    currentTime: player.currentTime,
    currentLiveTimestamp: null,
    currentOffsetFromLive: null,
    bufferedPosition: 0,
  });
  const { status, error } = useEvent(player, 'statusChange', { status: player.status, error: undefined });

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

  // Analytics Watch Time Tracker
  useEffect(() => {
    if (isPlaying && currentTime > lastPosition.current) {
      const delta = currentTime - lastPosition.current;
      // currentTime is in seconds in expo-video!
      if (delta > 0 && delta < 5) {
        watchTimeAccumulator.current += delta;
      }
    }
    lastPosition.current = currentTime;
  }, [currentTime, isPlaying]);

  useEffect(() => {
    const interval = setInterval(sendWatchTime, 30000);
    return () => {
      clearInterval(interval);
      sendWatchTime();
    };
  }, [sendWatchTime]);

  useEffect(() => {
    if (status === 'error') {
      setPlayerError(error?.message || 'Unable to load this video.');
      return;
    }

    if (status === 'readyToPlay') {
      setPlayerError(null);
    }
  }, [error?.message, status]);

  const isLoading = status === 'loading';

  return (
    <View style={styles.container}>
      {title && <Text style={styles.title}>{title}</Text>}
      <View style={styles.videoContainer}>
        {videoSource ? (
          <VideoView
            style={styles.video}
            player={player}
            fullscreenOptions={{ enable: true }}
            allowsPictureInPicture
            nativeControls
            contentFit="contain"
          />
        ) : null}
        {isLoading && (
          <View style={styles.loadingOverlay}>
            <ActivityIndicator size="large" color={colors.primary} />
          </View>
        )}
        {playerError && (
          <View style={styles.errorOverlay}>
            <Text style={styles.errorText}>{playerError}</Text>
          </View>
        )}
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
  errorOverlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'flex-end',
    padding: sizes.md,
    backgroundColor: 'rgba(0,0,0,0.35)',
  },
  errorText: {
    color: '#fff',
    fontSize: 13,
    lineHeight: 18,
  },
});
