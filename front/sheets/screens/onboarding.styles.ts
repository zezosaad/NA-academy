import { StyleSheet, Dimensions } from 'react-native';
import { colors } from '../../constants/helpers';

const { width, height } = Dimensions.get('window');

export const onboardingStyles = StyleSheet.create({
  container: {
    flex: 1,
  },

  safeArea: {
    flex: 1,
  },
  header: {
    width: '100%',
    flexDirection: 'row',
    justifyContent: 'flex-end',
    paddingHorizontal: 25,
    paddingTop: 15,
  },
  skipText: {
    color: colors.secondary,
    fontSize: 16,
    fontWeight: '600',
  },
  slide: {
    width,
    alignItems: 'center',
    paddingHorizontal: 30,
    paddingTop: height * 0.1,
  },
  iconWrapper: {
    width: width * 0.8,
    height: width * 0.8,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 40,
  },
  iconCircle: {
    width: 160,
    height: 160,
    borderRadius: 80,
    justifyContent: 'center',
    alignItems: 'center',
    borderStyle: 'dashed',
    borderWidth: 1,
    borderColor: 'white',
  },
  textContainer: {
    alignItems: 'center',
    width: '100%',
  },
  title: {
    fontWeight: '800',
    fontSize: 30,
    color: '#1E293B',
    marginBottom: 15,
    textAlign: 'center',
  },
  subtitle: {
    color: '#64748B',
    fontSize: 16,
    textAlign: 'center',
    lineHeight: 26,
    paddingHorizontal: 10,
  },
  footer: {
    paddingHorizontal: 30,
    paddingBottom: 40,
    gap: 40,
    alignItems: 'center',
  },
  pagination: {
    flexDirection: 'row',
    height: 8,
  },
  dot: {
    height: 8,
    borderRadius: 4,
    backgroundColor: colors.primary,
    marginHorizontal: 4,
  },
  nextButton: {
    width: '100%',
    backgroundColor: colors.primary,
    paddingVertical: 18,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: colors.primary,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.25,
    shadowRadius: 15,
    elevation: 4,
  },
  nextButtonText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 18,
  },
});
