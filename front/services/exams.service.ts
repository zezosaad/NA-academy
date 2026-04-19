import api from './api';
import { Exam, ExamScore, ExamStartResponse, SubmitExamPayload } from '../types/exam';

export const ExamsService = {
  getAll: async (params?: { page?: number; limit?: number; search?: string; subjectId?: string }): Promise<{ data: Exam[]; total: number; page: number; limit: number }> => {
    const response = await api.get('/exams', { params });
    return response.data.data ? response.data : { data: response.data, total: response.data.length || 0, page: params?.page || 1, limit: params?.limit || response.data.length || 0 };
  },

  getById: async (id: string, isFree?: boolean): Promise<Exam> => {
    const params = isFree ? { isFree: 'true' } : {};
    const response = await api.get(`/exams/${id}`, { params });
    return response.data.data || response.data;
  },

  start: async (examId: string, isFree: boolean = false): Promise<ExamStartResponse> => {
    const params = isFree ? { isFree: 'true' } : {};
    const response = await api.post(`/exams/${examId}/start`, {}, { params });
    return response.data.data || response.data;
  },

  submit: async (payload: SubmitExamPayload): Promise<ExamScore> => {
    const response = await api.post('/exams/submit', payload);
    return response.data.data || response.data;
  },
};
