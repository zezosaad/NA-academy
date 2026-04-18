import api from './api';
import { Exam, ExamScore, ExamStartResponse, SubmitExamPayload } from '../types/exam';

export const ExamsService = {
  getById: async (id: string, isFree?: boolean): Promise<Exam> => {
    const params = isFree ? { isFree: 'true' } : {};
    const response = await api.get(`/exams/${id}`, { params });
    return response.data.data || response.data;
  },

  start: async (examId: string, isFree: boolean = false): Promise<ExamStartResponse> => {
    const params = isFree ? { isFree: 'true' } : {};
    const response = await api.post(`/exams/${examId}/start`, null, { params });
    return response.data.data || response.data;
  },

  submit: async (payload: SubmitExamPayload): Promise<ExamScore> => {
    const response = await api.post('/exams/submit', payload);
    return response.data.data || response.data;
  },
};
