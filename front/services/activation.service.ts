import api from './api';

export const ActivationService = {
  activate: async (code: string): Promise<{ message: string; type: string; details: any }> => {
    const response = await api.post('/activation-codes/activate', { code });
    return response.data.data || response.data;
  },
};
