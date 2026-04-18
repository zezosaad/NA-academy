import api from './api';
import { MediaAsset } from '../types/media';

const BASE_URL = api.defaults.baseURL || '';

export const MediaService = {
  getBySubjectId: async (subjectId: string): Promise<MediaAsset[]> => {
    const response = await api.get(`/subjects/${subjectId}/media`);
    return response.data.data || response.data;
  },

  getStreamUrl: (mediaId: string): string => {
    return `${BASE_URL}/media/${mediaId}/stream`;
  },

  uploadChatMedia: async (formData: FormData): Promise<MediaAsset> => {
    const response = await api.post('/media/chat/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return response.data.data || response.data;
  },
};
