import { View, StyleSheet } from 'react-native';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { Stack } from 'expo-router';
import { height } from '@/constants/helpers';

export default function AuthLayout() {
    return (
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
                animation: 'fade'
            }}>
                <Stack.Screen name="login" />
                <Stack.Screen name="register" />
                <Stack.Screen name="onboarding" />
            </Stack>
        </View>
    );
}

import { authLayoutStyles as styles } from '../../sheets/screens/auth-layout.styles';