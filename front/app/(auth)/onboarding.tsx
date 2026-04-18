import React, { useRef, useState } from 'react';
import { View, Text, StyleSheet, Dimensions, FlatList, TouchableOpacity, ViewToken } from 'react-native';
import Animated, { useSharedValue, useAnimatedStyle, interpolate, Extrapolation } from 'react-native-reanimated';
import { Ionicons } from '@expo/vector-icons';
import { useAuthContext } from '../../contexts/AuthContext';
import { colors } from '../../constants/helpers';
import { SafeAreaView } from 'react-native-safe-area-context';

const { width, height } = Dimensions.get('window');

const ONBOARDING_DATA = [
  {
    id: '1',
    title: 'Discover Growth',
    subtitle: 'Step into a world of curated knowledge designed to elevate your skills seamlessly.',
    icon: 'compass-outline',
    blobColors: ['rgba(0, 102, 255, 0.4)', 'transparent'],
  },
  {
    id: '2',
    title: 'Learn at Your Pace',
    subtitle: 'Experience flexible learning that adapts to your unique lifestyle and schedule.',
    icon: 'book-outline',
    blobColors: ['rgba(56, 189, 248, 0.4)', 'transparent'],
  },
  {
    id: '3',
    title: 'Achieve Excellence',
    subtitle: 'Track your milestones and embrace a smarter way to reach your professional goals.',
    icon: 'ribbon-outline',
    blobColors: ['rgba(139, 92, 246, 0.3)', 'transparent'],
  },
];

export default function OnboardingScreen() {
  const { completeOnboarding } = useAuthContext();
  const [currentIndex, setCurrentIndex] = useState(0);
  const scrollX = useSharedValue(0);
  const flatListRef = useRef<FlatList>(null);

  const onViewableItemsChanged = useRef(({ viewableItems }: { viewableItems: ViewToken[] }) => {
    if (viewableItems.length > 0 && viewableItems[0].index !== null) {
      setCurrentIndex(viewableItems[0].index);
    }
  }).current;

  const handleFinish = async () => {
    await completeOnboarding();
  };

  const handleNext = () => {
    if (currentIndex < ONBOARDING_DATA.length - 1) {
      flatListRef.current?.scrollToIndex({ index: currentIndex + 1 });
    } else {
      handleFinish();
    }
  };


  const renderItem = ({ item }: { item: typeof ONBOARDING_DATA[0] }) => {
    return (
      <View style={styles.slide}>
        <View style={styles.iconWrapper}>
          <View style={styles.iconCircle}>
            <Ionicons name={item.icon as any} size={70} color={colors.primary} />
          </View>
        </View>

        <View style={styles.textContainer}>
          <Text style={styles.title}>{item.title}</Text>
          <Text style={styles.subtitle}>{item.subtitle}</Text>
        </View>
      </View>
    );
  };

  return (
    <View style={styles.container}>

      <SafeAreaView style={styles.safeArea}>
        <View style={styles.header}>
          <TouchableOpacity onPress={handleFinish}>
            <Text style={styles.skipText}>Skip</Text>
          </TouchableOpacity>
        </View>

        <Animated.FlatList
          ref={flatListRef}
          data={ONBOARDING_DATA}
          renderItem={renderItem}
          keyExtractor={(item) => item.id}
          horizontal
          showsHorizontalScrollIndicator={false}
          pagingEnabled
          bounces={false}
          onScroll={(e) => {
            scrollX.value = e.nativeEvent.contentOffset.x;
          }}
          scrollEventThrottle={16}
          onViewableItemsChanged={onViewableItemsChanged}
          viewabilityConfig={{ viewAreaCoveragePercentThreshold: 50 }}
        />

        <View style={styles.footer}>
          <View style={styles.pagination}>
            {ONBOARDING_DATA.map((_, i) => {
              const animatedDotStyle = useAnimatedStyle(() => {
                const dotWidth = interpolate(
                  scrollX.value,
                  [(i - 1) * width, i * width, (i + 1) * width],
                  [8, 24, 8],
                  Extrapolation.CLAMP
                );
                const opacity = interpolate(
                  scrollX.value,
                  [(i - 1) * width, i * width, (i + 1) * width],
                  [0.3, 1, 0.3],
                  Extrapolation.CLAMP
                );
                return { width: dotWidth, opacity };
              });

              return <Animated.View key={i} style={[styles.dot, animatedDotStyle]} />;
            })}
          </View>

          <TouchableOpacity style={styles.nextButton} onPress={handleNext}>
            <Text style={styles.nextButtonText}>
              {currentIndex === ONBOARDING_DATA.length - 1 ? 'Get Started' : 'Continue'}
            </Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    </View>
  );
}

import { onboardingStyles as styles } from '../../sheets/screens/onboarding.styles';
