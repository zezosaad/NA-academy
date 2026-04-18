import { StyleSheet } from 'react-native';
import { colors, sizes } from '../../constants/helpers';

export const customInputStyles = StyleSheet.create({
  inputContainer: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: sizes.sm,
    borderWidth: 1,
    borderColor: "#e1e1e1",
    paddingHorizontal: sizes.md,
    height: 55,
  },
  inputError: {
    borderColor: colors.danger,
  },
  errorText: {
    color: colors.danger,
    fontSize: 12,
    marginTop: -sizes.sm,
    marginLeft: sizes.xs,
  },
  inputIcon: {
    marginRight: sizes.sm,
  },
  input: {
    flex: 1,
    height: "100%",
    color: colors.dark,
    textAlign: "left",
  },
  eyeIcon: {
    padding: sizes.xs,
  },
});
