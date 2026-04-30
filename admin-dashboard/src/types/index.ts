// ── Auth ──
export interface LoginResponse {
  accessToken: string
  refreshToken: string
  user: { id: string; email: string; name: string; role: string }
}

export interface ApiError {
  message: string
  statusCode: number
}

// ── Users ──
export type UserRole = "student" | "teacher" | "admin"
export type UserStatus = "active" | "suspended" | "banned"

export interface User {
  _id: string
  name: string
  email: string
  role: UserRole
  status: UserStatus
  createdAt: string
  updatedAt: string
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
}

// ── Dashboard ──
export interface Activation {
  _id: string
  activatedBy: { name: string; email: string }
  activatedAt: string
}

export interface SecurityFlag {
  _id: string
  studentId: { name: string; email: string }
  flagType: "screen_recording" | "root_jailbreak" | "vpn_proxy" | "suspicious_activity"
  deviceId?: string
  actionTaken: "none" | "session_terminated" | "account_suspended" | "warning_issued"
  metadata?: Record<string, unknown>
  reviewedBy?: string
  reviewedAt?: string
  createdAt: string
}

export interface DashboardResponse {
  activeStudentsNow: number
  ongoingExams: number
  recentActivations: Activation[]
  securityFlags: SecurityFlag[]
}

// ── Education Levels ──
export type EducationLevel = "secondary_2" | "secondary_3" | "secondary_4"

export const EDUCATION_LEVEL_OPTIONS: { value: EducationLevel; label: string }[] = [
  { value: "secondary_2", label: "المستوى الثاني" },
  { value: "secondary_3", label: "المستوى الثالث" },
  { value: "secondary_4", label: "المستوى الرابع" },
]

// ── User Detail ──
export interface UserDetail {
  profile: {
    id: string
    name: string
    email: string
    role: UserRole
    status: UserStatus
    level?: EducationLevel
    createdAt: string
    updatedAt: string
  }
  device: {
    hardwareId: string
    isActive: boolean
    registeredAt: string
  } | null
  sessions: {
    activeCount: number
    lastActivityAt: string | null
  }
  activations: {
    subjects: Array<{
      codeId: string
      code: string
      activatedAt?: string
      activationDeviceId?: string
      subject: { id: string; title: string; category: string; level?: EducationLevel } | null
      bundle: { id: string; name: string } | null
    }>
    exams: Array<{
      codeId: string
      code: string
      status: CodeStatus
      usageType: UsageType
      maxUses?: number
      remainingUses?: number
      timeLimitMinutes?: number
      firstActivatedAt?: string
      exam: { id: string; title: string } | null
    }>
  }
  activity: {
    totalWatchSeconds: number
    watchTimeBySubject: Array<{
      subjectId: string
      subjectTitle?: string
      totalSeconds: number
      lastWatched: string
    }>
    examAttempts: Array<{
      sessionId: string
      examId: string
      examTitle?: string
      status: "started" | "completed" | "abandoned" | "timed_out"
      startedAt: string
      completedAt?: string
      isFreeAttempt: boolean
      scorePercentage?: number
      correctAnswers?: number
      totalQuestions?: number
    }>
  }
  securityFlags: Array<{
    id: string
    flagType: "screen_recording" | "root_jailbreak" | "vpn_proxy" | "suspicious_activity"
    actionTaken: "none" | "session_terminated" | "account_suspended" | "warning_issued"
    deviceId?: string
    createdAt: string
    reviewedAt?: string
  }>
}

// ── Subjects ──
export interface Subject {
  _id: string
  title: string
  description?: string
  category: string
  level?: EducationLevel
  isActive: boolean
  createdBy: string
  createdAt: string
  updatedAt: string
}

export interface SubjectBundle {
  _id: string
  name: string
  subjects: Subject[] | string[]
  isActive: boolean
  createdAt: string
  updatedAt: string
}

// ── Lessons ──
export interface Lesson {
  _id: string
  subjectId: string
  title: string
  description?: string
  order: number
  mediaId?: string
  isActive: boolean
  createdAt: string
  updatedAt: string
}

// ── Media ──
export type MediaType = "video" | "image"

export interface MediaAsset {
  _id: string
  gridFsFileId: string
  subjectId: string
  filename: string
  contentType: string
  fileSize: number
  mediaType: MediaType
  title?: string
  order: number
  uploadedBy: string
  createdAt: string
}

// ── Exams ──
export type ExamAccessMode = "code_required" | "free_section" | "full_exam_free_attempts"

export interface QuestionOption {
  label: string
  text: string
}

export interface Question {
  _id?: string
  text: string
  options: QuestionOption[]
  correctOption: string
  timeLimitSeconds: number
  imageRef?: string
  order: number
}

export interface Exam {
  _id: string
  title: string
  subjectId: string | Subject
  questions: Question[]
  accessMode?: ExamAccessMode
  hasFreeSection: boolean
  freeQuestionCount: number
  freeAttemptLimit: number
  freeAttemptsRemaining?: number
  isActive: boolean
  createdBy: string
  createdAt: string
  updatedAt: string
}

// ── Activation Codes ──
export type CodeStatus = "available" | "used" | "expired"
export type UsageType = "single" | "multi"

export interface SubjectCode {
  _id: string
  code: string
  subjectId?: string
  bundleId?: string
  status: CodeStatus
  batchId: string
  activatedBy?: { name: string; email: string }
  activatedAt?: string
  createdAt: string
}

export interface ExamCode {
  _id: string
  code: string
  examId: string
  usageType: UsageType
  maxUses: number
  remainingUses: number
  timeLimitMinutes?: number
  status: CodeStatus
  batchId: string
  activatedBy?: { name: string; email: string }
  activatedAt?: string
  createdAt: string
}

// ── Chat ──
export type ChatMessageStatus = "sent" | "delivered" | "read"
export type ChatMessageType = "text" | "image"

export interface ChatMessage {
  _id: string
  conversationId: string
  senderId: string | { _id: string; name: string; email: string; role: string }
  recipientId: string
  messageType: ChatMessageType
  text?: string
  imageFileId?: string
  status: ChatMessageStatus
  createdAt: string
  updatedAt: string
}

export interface ChatConversationPreview {
  id: string
  virtual: boolean
  counterpartyId: string
  counterpartyName: string
  counterpartyAvatarUrl: string | null
  subjectId: string
  subjectTitle: string
  lastMessage: {
    text?: string
    hasImage: boolean
    sentAt: string
    senderId: string
    status: ChatMessageStatus
  } | null
  unreadCount: number
}