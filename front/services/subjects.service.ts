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
};
