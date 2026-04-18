import { StyleSheet, Dimensions } from 'react-native';
import { colors, sizes } from '../../constants/helpers';

const { width } = Dimensions.get('window');

export const registerStyles = StyleSheet.create({
	container: {
		flex: 1,
		backgroundColor: "transparent",
	},
	keyboardView: {
		flex: 1,
	},
	content: {
		flexGrow: 1,
		justifyContent: "center",
		paddingHorizontal: sizes.lg,
		paddingBottom: sizes.xxxl,
	},
	header: {
		marginBottom: sizes.xxxl,
	},
	backButton: {
		width: width * 0.1,
		height: width * 0.1,
		borderRadius: width * 0.1,
		backgroundColor: "#fff",
		justifyContent: "center",
		alignItems: "center",
		shadowColor: "#000",
		shadowOffset: { width: 0, height: 2 },
		shadowOpacity: 0.1,
		shadowRadius: 4,
		elevation: 3,
		marginBottom: sizes.lg,
		alignSelf: 'flex-start'
	},
	headerTextContainer: {
		alignItems: "center",
	},
	title: {
		fontSize: 32,
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
	registerButton: {
		backgroundColor: colors.primary,
		height: 55,
		borderRadius: sizes.sm,
		justifyContent: "center",
		alignItems: "center",
		marginTop: sizes.lg,
		shadowColor: colors.primary,
		shadowOffset: { width: 0, height: 4 },
		shadowOpacity: 0.3,
		shadowRadius: 8,
		elevation: 5,
	},
	registerButtonText: {
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
	loginText: {
		color: colors.primary,
		fontSize: 15,
		fontWeight: "bold",
	},
});
