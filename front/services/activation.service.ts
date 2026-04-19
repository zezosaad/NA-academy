import api from './api';

export interface ActivationResponse {
  message: string;
  type: 'subject' | 'exam';
  examId?: string;
  activatedSubjects?: { id: string; title: string }[];
  timeLimitMinutes?: number;
  details?: any;
}

export const ActivationService = {
  activate: async (code: string): Promise<ActivationResponse> => {
    const response = await api.post('/activation-codes/activate', { code });
    return response.data.data || response.data;
  },
};
