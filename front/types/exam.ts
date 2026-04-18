export interface QuestionOption {
  label: string;
  text: string;
}

export interface Question {
  _id: string;
  text: string;
  options: QuestionOption[];
  correctOption?: string;
  timeLimitSeconds: number;
  imageRef?: string;
  order: number;
}

export interface Exam {
  _id: string;
  title: string;
  subjectId: string;
  questions: Question[];
  hasFreeSection: boolean;
  freeQuestionCount?: number;
  freeAttemptLimit?: number;
  isActive: boolean;
  createdBy?: string;
  createdAt: string;
  updatedAt: string;
}

export enum SessionStatus {
  STARTED = 'started',
  COMPLETED = 'completed',
  ABANDONED = 'abandoned',
  TIMED_OUT = 'timed_out',
}

export interface ExamSession {
  _id: string;
  studentId: string;
  examId: string;
  status: SessionStatus;
  startedAt: string;
  completedAt?: string;
  timeLimitMinutes?: number;
  responses: { questionId: string; selectedOption: string }[];
  isFreeAttempt: boolean;
}

export interface ExamScore {
  _id: string;
  sessionId: string;
  studentId: string;
  examId: string;
  totalQuestions: number;
  correctAnswers: number;
  scorePercentage: number;
  certificateGridFsId?: string;
  createdAt: string;
  updatedAt: string;
}

export interface SubmitExamPayload {
  examSessionId: string;
  answers: { questionId: string; selectedOption: string }[];
}

export interface ExamStartResponse {
  session: ExamSession;
  exam: Exam;
}
