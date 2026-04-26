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

// ── Subjects ──
export interface Subject {
  _id: string
  title: string
  description?: string
  category: string
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
  hasFreeSection: boolean
  freeQuestionCount: number
  freeAttemptLimit: number
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