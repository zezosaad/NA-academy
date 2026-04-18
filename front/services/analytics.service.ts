import api from './api';
import { StudentAnalytics, WatchTimePayload } from '../types/analytics';

export const AnalyticsService = {
  getMyAnalytics: async (): Promise<StudentAnalytics> => {
    const response = await api.get('/analytics/student/me');
    return response.data.data || response.data;
  },

  trackWatchTime: async (payload: WatchTimePayload): Promise<void> => {
    await api.post('/analytics/watch-time', payload);
  },
};
