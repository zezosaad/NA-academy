import axios, { AxiosError } from 'axios';
import * as SecureStore from 'expo-secure-store';
import { NativeModules, Platform } from 'react-native';
import Constants from "expo-constants";

// When testing locally on Android emulator use 10.0.2.2 instead of localhost
// For iOS Simulator, localhost works. For physical devices, use your computer's IP.
// ─── IP Discovery ────────────────────────────────────────────────────────────

const getLocalIp = () => {
  if (__DEV__) {
    const scriptURL = NativeModules.SourceCode?.scriptURL;
    if (scriptURL) {
      const match = scriptURL.match(/https?:\/\/([^:]+)/);
      if (
        match &&
        match[1] &&
        match[1] !== "localhost" &&
        match[1] !== "10.0.2.2"
      ) {
        return match[1];
      }
    }
  }
  const debuggerHost = Constants.expoConfig?.hostUri;
  if (debuggerHost) {
    return debuggerHost.split(":")[0];
  }
  return Platform.OS === "android" ? "10.0.2.2" : "localhost";
};

const DEFAULT_LOCAL_IP = getLocalIp();

export const SERVER_URL =
  process.env.EXPO_PUBLIC_API_URL ||
  (Platform.select({
    android: `http://${DEFAULT_LOCAL_IP}:3000`,
    ios: `http://${DEFAULT_LOCAL_IP}:3000`,
    default: `http://${DEFAULT_LOCAL_IP}:3000`,
  }) as string);

export const API_BASE_URL = `${SERVER_URL}/api/v1`;

export const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000, // 10s default timeout
  headers: {
    'Content-Type': 'application/json',
  },
});

export const TOKEN_KEY = 'na_academy_access_token';

// Request Interceptor: Attach JWT Token implicitly
api.interceptors.request.use(
  async (config) => {
    try {
      const token = await SecureStore.getItemAsync(TOKEN_KEY);
      if (token && config.headers) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    } catch (error) {
      console.error('Error fetching token from SecureStore', error);
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response Interceptor: Global Error Handling, 401s auto-logout
api.interceptors.response.use(
  (response) => {
    // If the response is successful, just return the data directly
    return response.data;
  },
  async (error: AxiosError) => {
    if (error.response) {
      const status = error.response.status;

      if (status === 401) {
        // Token expired or Unauthorized - Handle Logout locally
        console.warn('Session expired or Unauthorized. Logging out...');
        try {
          await SecureStore.deleteItemAsync(TOKEN_KEY);
          // TODO: Trigger Context API or State Management to kick user to Login Screen
        } catch (e) {
          console.error('Error clearing token', e);
        }
      } else if (status === 403) {
        // Forbidden - For instance 'Hardware Device mismatch' triggers this locally
        console.warn('Forbidden: Check hardware ID or access constraints.');
      } else if (status === 429) {
        console.warn('Rate Limit hit! Slow down.');
      }
    } else if (error.request) {
      console.warn('No response received from server. Check network connection.');
    }

    // Pass the error back down the chain so individual components can catch it
    return Promise.reject(error);
  }
);

export default api;
