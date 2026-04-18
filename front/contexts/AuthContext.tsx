import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import * as SecureStore from 'expo-secure-store';
import api, { setLogoutCallback } from '../services/api';

interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  status?: string;
}

interface AuthContextType {
  isAuthenticated: boolean;
  user: User | null;
  token: string | null;
  loginStateUpdate: (token: string, refreshToken?: string, user?: User) => Promise<void>;
  logout: () => Promise<void>;
  isAppInitialized: boolean;
  hasSeenOnboarding: boolean;
  completeOnboarding: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [isAppInitialized, setIsAppInitialized] = useState(false);
  const [hasSeenOnboarding, setHasSeenOnboarding] = useState(false);

  const fetchUserProfile = async () => {
    try {
      const response = await api.get('/users/me');
      const userData = response.data.data || response.data;
      if (userData) setUser(userData);
    } catch (error) {
      console.error('Failed to fetch user profile', error);
    }
  };

  useEffect(() => {
    const checkAuthStatus = async () => {
      try {
        const seenOnboarding = await SecureStore.getItemAsync('hasSeenOnboarding');
        if (seenOnboarding === 'true') {
          setHasSeenOnboarding(true);
        }

        const storedToken = await SecureStore.getItemAsync('accessToken');
        if (storedToken) {
          setToken(storedToken);
          await fetchUserProfile();
        }
      } catch (error) {
        console.error('Error checking auth state', error);
      } finally {
        setIsAppInitialized(true);
      }
    };
    checkAuthStatus();
  }, []);

  const loginStateUpdate = async (newToken: string, newRefreshToken?: string, newUser?: User) => {
    try {
      const tokenStr = typeof newToken === 'string' ? newToken : JSON.stringify(newToken);
      setToken(tokenStr);
      if (newUser) setUser(newUser);

      if (tokenStr) {
        await SecureStore.setItemAsync('accessToken', tokenStr);
      }
      if (newRefreshToken) {
        const refreshStr = typeof newRefreshToken === 'string' ? newRefreshToken : JSON.stringify(newRefreshToken);
        await SecureStore.setItemAsync('refreshToken', refreshStr);
      }
    } catch (e) {
      console.error('Failed to save tokens in context', e);
    }
  };

  const completeOnboarding = async () => {
    await SecureStore.setItemAsync('hasSeenOnboarding', 'true');
    setHasSeenOnboarding(true);
  };

  const logout = async () => {
    setToken(null);
    setUser(null);
    await SecureStore.deleteItemAsync('accessToken');
    await SecureStore.deleteItemAsync('refreshToken');
  };

  useEffect(() => {
    setLogoutCallback(logout);
  }, []);

  return (
    <AuthContext.Provider value={{ isAuthenticated: !!token, user, token, loginStateUpdate, logout, isAppInitialized, hasSeenOnboarding, completeOnboarding }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuthContext = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuthContext must be used within an AuthProvider");
  }
  return context;
};
