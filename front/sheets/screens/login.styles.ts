import { StyleSheet } from 'react-native';
import { colors, sizes } from '../../constants/helpers';

export const loginStyles = StyleSheet.create({
	container: {
		flex: 1,
		backgroundColor: "transparent",
	},
	content: {
		flex: 1,
		paddingHorizontal: sizes.lg,
		justifyContent: "center",
	},
	header: {
		alignItems: "center",
		marginBottom: sizes.xxxl,
	},
	logoContainer: {
		width: 100,
		height: 100,
		borderRadius: 50,
		backgroundColor: `${colors.primary}15`,
		justifyContent: "center",
		alignItems: "center",
		marginBottom: sizes.lg,
	},
	title: {
		fontSize: 28,
		fontWeight: "bold",
		color: colors.dark,
		marginBottom: sizes.xs,
		textAlign: "center",
	},
	subtitle: {
		fontSize: 16,
		color: colors.secondary,
		textAlign: "center",
	},
	form: {
		gap: sizes.md,
	},
	forgotPassword: {
		alignSelf: "flex-end",
		marginTop: sizes.xs,
	},
	forgotPasswordText: {
		color: colors.primary,
		fontSize: 14,
		fontWeight: "500",
	},
	loginButton: {
		backgroundColor: colors.primary,
		height: 55,
		borderRadius: sizes.sm,
		justifyContent: "center",
		alignItems: "center",
		marginTop: sizes.md,
		shadowColor: colors.primary,
		shadowOffset: { width: 0, height: 4 },
		shadowOpacity: 0.3,
		shadowRadius: 8,
		elevation: 5,
	},
	loginButtonText: {
		color: colors.light,
		fontSize: 18,
		fontWeight: "bold",
	},
	footer: {
		flexDirection: "row",
		justifyContent: "center",
		alignItems: "center",
		marginTop: sizes.xxxl,
		gap: sizes.xs,
	},
	footerText: {
		color: colors.secondary,
		fontSize: 15,
	},
	registerText: {
		color: colors.primary,
		fontSize: 15,
		fontWeight: "bold",
	},
});
