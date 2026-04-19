import { useEffect } from "react";
import { ThemeProvider, DefaultTheme } from "@react-navigation/native";
import { router, Stack } from "expo-router";
import { SafeAreaProvider } from "react-native-safe-area-context";
import Toast from "react-native-toast-message";
import { AuthProvider, useAuthContext } from "../contexts/AuthContext";
import { ChatProvider } from "../contexts/ChatContext";
import { StatusBar, View, StyleSheet, Dimensions } from "react-native";
import { colors } from "@/constants/helpers";
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';

const { height: SCREEN_HEIGHT } = Dimensions.get('window');

const AppTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: 'transparent',
  },
};

function RootNavigation() {
  const { isAuthenticated, isAppInitialized, hasSeenOnboarding, token } = useAuthContext();

  useEffect(() => {
    if (!isAppInitialized) return;

    if (isAuthenticated) {
      router.replace("/(tabs)");
    } else if (hasSeenOnboarding) {
      router.replace("/(auth)/login");
    } else {
      router.replace("/(auth)/onboarding");
    }
  }, [isAuthenticated, isAppInitialized, hasSeenOnboarding]);

  return (
    <ChatProvider token={token}>
      <View style={styles.container}>
        <View style={StyleSheet.absoluteFill} pointerEvents="none">
          <LinearGradient
            colors={['rgba(0, 102, 255, 0.6)', 'transparent']}
            start={{ x: 0, y: 0 }}
            end={{ x: 0, y: 1 }}
            style={styles.gradient}
          />

          <BlurView intensity={90} tint="light" style={StyleSheet.absoluteFill} />
        </View>

        <Stack screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: 'transparent' },
        }}>
          <Stack.Screen name="(auth)" />
          <Stack.Screen name="(tabs)" />
        </Stack>
        <Toast />
        <StatusBar
          barStyle="dark-content"
          backgroundColor={colors.primary}
        />
      </View>
    </ChatProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fc',
  },
  gradient: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: SCREEN_HEIGHT * 0.4,
  },
});

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <ThemeProvider value={AppTheme}>
        <AuthProvider>
          <RootNavigation />
        </AuthProvider>
      </ThemeProvider>
    </SafeAreaProvider>
  );
}
