import api from './api';
import { Message } from '../types/chat';

export const ChatRestService = {
  getPendingMessages: async (): Promise<Message[]> => {
    const response = await api.get('/chat/pending');
    return response.data.data || response.data;
  },
};
