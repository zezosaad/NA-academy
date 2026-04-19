import axios from 'axios';
import { Platform } from 'react-native';
import * as SecureStore from 'expo-secure-store';
import { buildBearerToken, normalizeToken } from '../utils/auth-token';

const FALLBACK_URL = Platform.OS === 'android' ? 'http://10.0.2.2:3000/api/v1' : 'http://localhost:3000/api/v1';
const BASE_URL = process.env.EXPO_PUBLIC_API_URL || FALLBACK_URL;

export const api = axios.create({
  baseURL: BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use(
  async (config) => {
    const token = await SecureStore.getItemAsync('accessToken');
    const authHeader = buildBearerToken(token);
    if (authHeader) {
      config.headers.Authorization = authHeader;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

let isRefreshing = false;
let failedQueue: { resolve: (token: string) => void; reject: (err: any) => void }[] = [];

const processQueue = (error: any, token: string | null = null) => {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error);
    } else {
      prom.resolve(token!);
    }
  });
  failedQueue = [];
};

// Logout callback — set by AuthProvider at mount time
let logoutCallback: (() => Promise<void>) | null = null;
export const setLogoutCallback = (cb: () => Promise<void>) => {
  logoutCallback = cb;
};

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        }).then((token) => {
          originalRequest.headers.Authorization = buildBearerToken(token as string | null | undefined) ?? '';
          return api(originalRequest);
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        const refreshToken = await SecureStore.getItemAsync('refreshToken');
        if (!refreshToken) throw new Error('No refresh token');

        const { data } = await axios.post(`${BASE_URL}/auth/refresh`, { refreshToken });
        const newToken = normalizeToken(data.data?.accessToken || data.accessToken);
        const newRefresh = data.data?.refreshToken || data.refreshToken;

        if (!newToken) throw new Error('Invalid access token returned from refresh');

        await SecureStore.setItemAsync('accessToken', newToken);
        if (newRefresh) {
          await SecureStore.setItemAsync('refreshToken', newRefresh);
        }

        processQueue(null, newToken);
        originalRequest.headers.Authorization = buildBearerToken(newToken) ?? '';
        return api(originalRequest);
      } catch (refreshError) {
        processQueue(refreshError, null);
        if (logoutCallback) await logoutCallback();
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  }
);

export default api;
