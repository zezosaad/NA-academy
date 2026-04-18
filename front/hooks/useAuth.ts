import { useState } from 'react';
import { AuthService } from '../services/auth.service';
import { LoginData, RegisterData } from '../types/auth';
import { router, useRouter } from 'expo-router';
import * as SecureStore from 'expo-secure-store';
import Toast from 'react-native-toast-message';
import * as Application from 'expo-application';
import { Platform } from 'react-native';
import { zodResolver } from '@hookform/resolvers/zod';
import { LoginFormValues, loginSchema, RegisterFormValues, registerSchema } from '@/validations/auth.validation';
import { useForm } from 'react-hook-form';
import { useAuthContext } from '../contexts/AuthContext';

const getHardwareId = async (): Promise<string> => {
  let deviceId: string | null = null;

  if (Platform.OS === 'android') {
    deviceId = Application.getAndroidId();
  } else if (Platform.OS === 'ios') {
    deviceId = await Application.getIosIdForVendorAsync();
  }

  // Fallback if null (e.g. on Web)
  if (!deviceId) {
    deviceId = await SecureStore.getItemAsync('fallbackHardwareId');
    if (!deviceId) {
      deviceId = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
      await SecureStore.setItemAsync('fallbackHardwareId', deviceId);
    }
  }

  return deviceId;
};

export const useAuth = () => {
  const [loading, setLoading] = useState(false);
  const { loginStateUpdate } = useAuthContext();
  const { control, handleSubmit, formState: { errors } } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "" },
  });

  const handleLogin = async (data: Omit<LoginData, 'hardwareId'>) => {
    setLoading(true);
    try {
      const hardwareId = await getHardwareId();
      const response = await AuthService.login({
        ...data,
        hardwareId,
      });

      await loginStateUpdate(response.accessToken, response.refreshToken, response.user);

      Toast.show({
        type: 'success',
        text1: 'Success',
        text2: 'Logged in successfully!',
      });

      router.replace('/(tabs)');
    } catch (error: any) {
      console.error(error);
      const message = error.response?.data?.message || 'Invalid credentials';
      Toast.show({
        type: 'error',
        text1: 'Error',
        text2: typeof message === 'string' ? message : 'Something went wrong',
      });
    } finally {
      setLoading(false);
    }
  };

  const { control: registerControl, handleSubmit: registerHandleSubmit, formState: { errors: registerErrors } } = useForm<RegisterFormValues>({
    resolver: zodResolver(registerSchema),
    defaultValues: { name: "", email: "", password: "" },
  });
  const handleRegister = async (data: Omit<RegisterData, 'hardwareId'>) => {
    setLoading(true);
    try {
      const hardwareId = await getHardwareId();
      const response = await AuthService.register({
        ...data,
        hardwareId,
      });

      await loginStateUpdate(response.accessToken, response.refreshToken, response.user);

      Toast.show({
        type: 'success',
        text1: 'Success',
        text2: 'Account created successfully!',
      });

      router.replace('/(tabs)');
    } catch (error: any) {
      console.error(error);
      const message = error.response?.data?.message || 'Something went wrong';
      Toast.show({
        type: 'error',
        text1: 'Error',
        text2: typeof message === 'string' ? message : 'Something went wrong',
      });
    } finally {
      setLoading(false);
    }
  };

  return { handleLogin, handleRegister, loading, control, handleSubmit, errors, registerControl, registerHandleSubmit, registerErrors };
};
