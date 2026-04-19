export interface User {
  name: string
  email: string
}

export interface Activation {
  _id: string
  activatedBy: User
  activatedAt: string
}

export interface SecurityFlag {
  _id: string
  studentId: User
  description: string
  createdAt: string
  actionTaken: "NONE" | "REVIEWED" | "DISMISSED"
}

export interface DashboardResponse {
  activeStudentsNow: number
  ongoingExams: number
  recentActivations: Activation[]
  securityFlags: SecurityFlag[]
}

export interface ApiError {
  message: string
  statusCode: number
}