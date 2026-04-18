export interface LoginData {
  email: string;
  password: string;
  hardwareId: string;
}

export interface RegisterData {
  name: string;
  email: string;
  password: string;
  hardwareId: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken?: string;
  user?: any;
}
