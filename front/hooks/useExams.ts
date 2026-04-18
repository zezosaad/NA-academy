import { useState, useCallback } from 'react';
import { ExamsService } from '../services/exams.service';
import { Exam, ExamScore, ExamSession, SubmitExamPayload } from '../types/exam';

export const useExams = () => {
  const [loading, setLoading] = useState(false);
  const [exam, setExam] = useState<Exam | null>(null);
  const [session, setSession] = useState<ExamSession | null>(null);
  const [score, setScore] = useState<ExamScore | null>(null);

  const fetchExam = useCallback(async (id: string, isFree?: boolean) => {
    setLoading(true);
    try {
      const data = await ExamsService.getById(id, isFree);
      setExam(data);
      return data;
    } catch (error) {
      console.error('Failed to fetch exam', error);
      throw error;
    } finally {
      setLoading(false);
    }
  }, []);

  const startExam = useCallback(async (examId: string, isFree: boolean = false) => {
    setLoading(true);
    try {
      const data = await ExamsService.start(examId, isFree);
      setSession(data.session);
      setExam(data.exam);
      return data;
    } catch (error) {
      console.error('Failed to start exam', error);
      throw error;
    } finally {
      setLoading(false);
    }
  }, []);

  const submitExam = useCallback(async (payload: SubmitExamPayload) => {
    setLoading(true);
    try {
      const data = await ExamsService.submit(payload);
      setScore(data);
      return data;
    } catch (error) {
      console.error('Failed to submit exam', error);
      throw error;
    } finally {
      setLoading(false);
    }
  }, []);

  return { exam, session, score, loading, fetchExam, startExam, submitExam };
};
