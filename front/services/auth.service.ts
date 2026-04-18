import api from './api';
import { LoginData, RegisterData, AuthResponse } from '../types/auth';

export const AuthService = {
  login: async (data: LoginData): Promise<AuthResponse> => {
    const response = await api.post('/auth/login', data);
    return response.data.data || response.data;
  },

  register: async (data: RegisterData): Promise<AuthResponse> => {
    const response = await api.post('/auth/register', data);
    return response.data.data || response.data;
  },
};
