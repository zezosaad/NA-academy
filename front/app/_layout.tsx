import { useEffect } from "react";
import { router, Stack } from "expo-router";
import { SafeAreaProvider } from "react-native-safe-area-context";
import Toast from "react-native-toast-message";
import { AuthProvider, useAuthContext } from "../contexts/AuthContext";
import { ChatProvider } from "../contexts/ChatContext";
import { StatusBar } from "react-native";
import { colors } from "@/constants/helpers";

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
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="(auth)" />
        <Stack.Screen name="(tabs)" />
      </Stack>
      <Toast />
      <StatusBar
        barStyle="dark-content"
        backgroundColor={colors.primary}
      />
    </ChatProvider>
  );
}

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <RootNavigation />
      </AuthProvider>
    </SafeAreaProvider>
  );
}
