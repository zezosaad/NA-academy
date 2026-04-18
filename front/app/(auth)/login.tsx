import React from "react";
import { Text, View, TouchableOpacity, StyleSheet, KeyboardAvoidingView, Platform, ActivityIndicator } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { colors, sizes } from "../../constants/helpers";
import { Ionicons } from "@expo/vector-icons";
import { Link } from "expo-router";
import Animated, { FadeInDown, FadeInUp } from "react-native-reanimated";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { loginSchema, LoginFormValues } from "../../validations/auth.validation";
import { useAuth } from "../../hooks/useAuth";
import CustomInput from "../../components/CustomInput";

export default function Login() {
	const { handleLogin, loading, control, handleSubmit } = useAuth();

	return (
		<SafeAreaView style={styles.container}>
			<KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : "height"} style={styles.content}>
				<Animated.View entering={FadeInDown.delay(200).duration(800)} style={styles.header}>
					<View style={styles.logoContainer}>
						<Ionicons name="school" size={60} color={colors.primary} />
					</View>
					<Text style={styles.title}>Welcome Back</Text>
					<Text style={styles.subtitle}>Please log in to continue</Text>
				</Animated.View>

				<Animated.View entering={FadeInUp.delay(400).duration(800)} style={styles.form}>
					<CustomInput
						control={control}
						name="email"
						iconName="mail-outline"
						placeholder="Email Address"
						keyboardType="email-address"
					/>

					<CustomInput
						control={control}
						name="password"
						iconName="lock-closed-outline"
						placeholder="Password"
						secureTextEntry
					/>

					<TouchableOpacity style={styles.forgotPassword}>
						<Text style={styles.forgotPasswordText}>Forgot Password?</Text>
					</TouchableOpacity>

					<TouchableOpacity style={styles.loginButton} onPress={handleSubmit(handleLogin)} disabled={loading}>
						{loading ? (
							<ActivityIndicator color={colors.light} />
						) : (
							<Text style={styles.loginButtonText}>Log In</Text>
						)}
					</TouchableOpacity>
				</Animated.View>

				<Animated.View entering={FadeInUp.delay(600).duration(800)} style={styles.footer}>
					<Text style={styles.footerText}>Don't have an account?</Text>
					<Link href="/(auth)/register" asChild>
						<TouchableOpacity>
							<Text style={styles.registerText}>Create new account</Text>
						</TouchableOpacity>
					</Link>
				</Animated.View>
			</KeyboardAvoidingView>
		</SafeAreaView>
	);
}

import { loginStyles as styles } from '../../sheets/screens/login.styles';
