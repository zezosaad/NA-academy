import api from './api';
import { Subject, SubjectsListResponse, SubjectsQueryParams } from '../types/subject';

export const SubjectsService = {
  getAll: async (params?: SubjectsQueryParams): Promise<SubjectsListResponse> => {
    const response = await api.get('/subjects', { params });
    return response.data;
  },

  getById: async (id: string): Promise<Subject> => {
    const response = await api.get(`/subjects/${id}`);
    return response.data.data || response.data;
  },

  create: async (data: Partial<Subject>): Promise<Subject> => {
    const response = await api.post('/subjects', data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/subjects/${id}`);
  },
};
