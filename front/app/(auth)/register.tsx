import React from "react";
import { Text, View, TouchableOpacity, StyleSheet, KeyboardAvoidingView, Platform, ActivityIndicator, ScrollView } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { colors, sizes, width } from "../../constants/helpers";
import { Link, useRouter } from "expo-router";
import Animated, { FadeInDown, FadeInUp } from "react-native-reanimated";
import { useAuth } from "../../hooks/useAuth";
import CustomInput from "../../components/CustomInput";

export default function Register() {
	const router = useRouter();
	const { handleRegister, loading, registerControl, registerHandleSubmit } = useAuth();


	return (
		<SafeAreaView style={styles.container}>
			<KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : "height"} style={styles.keyboardView}>
				<ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
					<Animated.View entering={FadeInDown.delay(200).duration(800)} style={styles.header}>
						<View style={styles.headerTextContainer}>
							<Text style={styles.title}>Create Account</Text>
							<Text style={styles.subtitle}>Join us and start your educational journey</Text>
						</View>
					</Animated.View>

					<Animated.View entering={FadeInUp.delay(400).duration(800)} style={styles.form}>
						<CustomInput
							control={registerControl}
							name="name"
							iconName="person-outline"
							placeholder="Full Name"
						/>

						<CustomInput
							control={registerControl}
							name="email"
							iconName="mail-outline"
							placeholder="Email Address"
							keyboardType="email-address"
						/>

						<CustomInput
							control={registerControl}
							name="password"
							iconName="lock-closed-outline"
							placeholder="Password"
							secureTextEntry
						/>

						<TouchableOpacity style={styles.registerButton} onPress={registerHandleSubmit(handleRegister)} disabled={loading}>
							{loading ? (
								<ActivityIndicator color={colors.light} />
							) : (
								<Text style={styles.registerButtonText}>Sign Up</Text>
							)}
						</TouchableOpacity>
					</Animated.View>

					<Animated.View entering={FadeInUp.delay(600).duration(800)} style={styles.footer}>
						<Text style={styles.footerText}>Already have an account?</Text>
						<Link href="/(auth)/login" asChild>
							<TouchableOpacity>
								<Text style={styles.loginText}>Log In</Text>
							</TouchableOpacity>
						</Link>
					</Animated.View>
				</ScrollView>
			</KeyboardAvoidingView>
		</SafeAreaView>
	);
}

import { registerStyles as styles } from '../../sheets/screens/register.styles';
