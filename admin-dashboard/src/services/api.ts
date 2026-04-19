import type {
  DashboardResponse,
  LoginResponse,
  ApiError,
  User,
  PaginatedResponse,
  Subject,
  SubjectBundle,
  Exam,
  SubjectCode,
  ExamCode,
  MediaAsset,
  SecurityFlag,
  UserStatus,
} from "@/types"

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:3000"

class ApiClient {
  private baseUrl: string

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl
  }

  private getToken(): string | null {
    return localStorage.getItem("auth_token")
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {},
    isPublic = false
  ): Promise<T> {
    const token = this.getToken()

    const headers: HeadersInit = {
      ...options.headers,
    }

    // Only set Content-Type for non-FormData requests
    if (!(options.body instanceof FormData)) {
      ;(headers as Record<string, string>)["Content-Type"] = "application/json"
    }

    if (!isPublic && token) {
      ;(headers as Record<string, string>)["Authorization"] = `Bearer ${token}`
    }

    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      ...options,
      headers,
    })

    if (!response.ok) {
      if (response.status === 401) {
        localStorage.removeItem("auth_token")
      }

      let message: string
      try {
        const body = await response.json()
        message =
          body?.message || body?.data?.message || `HTTP error ${response.status}`
      } catch {
        message = `HTTP error ${response.status}`
      }

      if (response.status === 403) {
        message = message.includes("Device mismatch")
          ? message
          : `Access denied (403) - ${message}`
      }

      const error: ApiError = { message, statusCode: response.status }
      throw error
    }

    // Handle 204 No Content
    if (response.status === 204) return undefined as T

    const json = await response.json()
    return json.data !== undefined ? json.data : json
  }

  // ── Auth ──
  async login(email: string, password: string): Promise<LoginResponse> {
    const data = await this.request<LoginResponse>(
      "/api/v1/auth/login",
      {
        method: "POST",
        body: JSON.stringify({ email, password, hardwareId: "admin-dashboard" }),
      },
      true
    )
    localStorage.setItem("auth_token", data.accessToken)
    return data
  }

  async logout(): Promise<void> {
    try {
      await this.request("/api/v1/auth/logout", { method: "POST" })
    } finally {
      localStorage.removeItem("auth_token")
    }
  }

  // ── Dashboard ──
  async getDashboard(): Promise<DashboardResponse> {
    return this.request<DashboardResponse>("/api/v1/admin/dashboard")
  }

  // ── Users ──
  async getUsers(params: {
    page?: number
    limit?: number
    search?: string
    role?: string
    status?: string
  } = {}): Promise<PaginatedResponse<User>> {
    const qs = new URLSearchParams()
    if (params.page) qs.set("page", String(params.page))
    if (params.limit) qs.set("limit", String(params.limit))
    if (params.search) qs.set("search", params.search)
    if (params.role) qs.set("role", params.role)
    if (params.status) qs.set("status", params.status)
    return this.request(`/api/v1/users?${qs}`)
  }

  async updateUserStatus(userId: string, status: UserStatus): Promise<User> {
    return this.request(`/api/v1/users/${userId}/status`, {
      method: "PATCH",
      body: JSON.stringify({ status }),
    })
  }

  async resetUserDevice(userId: string): Promise<void> {
    return this.request(`/api/v1/users/${userId}/device-reset`, {
      method: "PATCH",
    })
  }

  // ── Subjects ──
  async getSubjects(params: {
    page?: number
    limit?: number
    search?: string
    category?: string
  } = {}): Promise<PaginatedResponse<Subject>> {
    const qs = new URLSearchParams()
    if (params.page) qs.set("page", String(params.page))
    if (params.limit) qs.set("limit", String(params.limit))
    if (params.search) qs.set("search", params.search)
    if (params.category) qs.set("category", params.category)
    return this.request(`/api/v1/subjects?${qs}`)
  }

  async createSubject(data: {
    title: string
    description?: string
    category: string
  }): Promise<Subject> {
    return this.request("/api/v1/subjects", {
      method: "POST",
      body: JSON.stringify(data),
    })
  }

  async updateSubject(
    id: string,
    data: { title?: string; description?: string; category?: string }
  ): Promise<Subject> {
    return this.request(`/api/v1/subjects/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    })
  }

  async deleteSubject(id: string): Promise<void> {
    return this.request(`/api/v1/subjects/${id}`, { method: "DELETE" })
  }

  // ── Subject Bundles ──
  async getBundles(): Promise<SubjectBundle[]> {
    return this.request("/api/v1/subject-bundles")
  }

  async createBundle(data: {
    name: string
    subjectIds: string[]
  }): Promise<SubjectBundle> {
    return this.request("/api/v1/subject-bundles", {
      method: "POST",
      body: JSON.stringify(data),
    })
  }

  async updateBundle(
    id: string,
    data: { name?: string; subjectIds?: string[] }
  ): Promise<SubjectBundle> {
    return this.request(`/api/v1/subject-bundles/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    })
  }

  async deleteBundle(id: string): Promise<void> {
    return this.request(`/api/v1/subject-bundles/${id}`, { method: "DELETE" })
  }

  // ── Media ──
  async getSubjectMedia(subjectId: string): Promise<MediaAsset[]> {
    return this.request(`/api/v1/subjects/${subjectId}/media`)
  }

  async uploadMedia(
    subjectId: string,
    file: File,
    mediaType: "video" | "image",
    title?: string,
    onProgress?: (pct: number) => void
  ): Promise<MediaAsset> {
    const token = this.getToken()
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest()
      xhr.open("POST", `${this.baseUrl}/api/v1/media/upload`)
      if (token) xhr.setRequestHeader("Authorization", `Bearer ${token}`)

      if (onProgress) {
        xhr.upload.onprogress = (e) => {
          if (e.lengthComputable) onProgress(Math.round((e.loaded / e.total) * 100))
        }
      }

      xhr.onload = () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          const json = JSON.parse(xhr.responseText)
          resolve(json.data !== undefined ? json.data : json)
        } else {
          reject({ message: `Upload failed: ${xhr.status}`, statusCode: xhr.status })
        }
      }
      xhr.onerror = () => reject({ message: "Upload failed", statusCode: 0 })

      const fd = new FormData()
      fd.append("file", file)
      fd.append("subjectId", subjectId)
      fd.append("mediaType", mediaType)
      if (title) fd.append("title", title)
      xhr.send(fd)
    })
  }

  async deleteMedia(id: string): Promise<void> {
    return this.request(`/api/v1/media/${id}`, { method: "DELETE" })
  }

  getStreamUrl(id: string): string {
    return `${this.baseUrl}/api/v1/media/${id}/stream`
  }

  // ── Exams ──
  async getExams(params: {
    page?: number
    limit?: number
    search?: string
    subjectId?: string
  } = {}): Promise<PaginatedResponse<Exam>> {
    const qs = new URLSearchParams()
    if (params.page) qs.set("page", String(params.page))
    if (params.limit) qs.set("limit", String(params.limit))
    if (params.search) qs.set("search", params.search)
    if (params.subjectId) qs.set("subjectId", params.subjectId)
    return this.request(`/api/v1/exams?${qs}`)
  }

  async getExam(id: string): Promise<Exam> {
    return this.request(`/api/v1/exams/${id}`)
  }

  async createExam(data: {
    title: string
    subjectId: string
    hasFreeSection?: boolean
    freeQuestionCount?: number
    freeAttemptLimit?: number
    questions: {
      text: string
      options: { label: string; text: string }[]
      correctOption: string
      timeLimitSeconds: number
      imageRef?: string
      order: number
    }[]
  }): Promise<Exam> {
    return this.request("/api/v1/exams", {
      method: "POST",
      body: JSON.stringify(data),
    })
  }

  async updateExam(id: string, data: Partial<Parameters<typeof this.createExam>[0]>): Promise<Exam> {
    return this.request(`/api/v1/exams/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    })
  }

  async deleteExam(id: string): Promise<void> {
    return this.request(`/api/v1/exams/${id}`, { method: "DELETE" })
  }

  // ── Activation Codes ──
  async generateSubjectCodes(data: {
    subjectId?: string
    bundleId?: string
    quantity: number
  }): Promise<{ batchId: string; codes: SubjectCode[] }> {
    return this.request("/api/v1/activation-codes/subject/generate", {
      method: "POST",
      body: JSON.stringify(data),
    })
  }

  async generateExamCodes(data: {
    examId: string
    quantity: number
    usageType: "single" | "multi"
    maxUses?: number
    timeLimitMinutes?: number
  }): Promise<{ batchId: string; codes: ExamCode[] }> {
    return this.request("/api/v1/activation-codes/exam/generate", {
      method: "POST",
      body: JSON.stringify(data),
    })
  }

  async getBatchCodes(batchId: string): Promise<(SubjectCode | ExamCode)[]> {
    return this.request(`/api/v1/activation-codes/batch/${batchId}`)
  }

  async exportBatch(batchId: string, format: "csv" | "xlsx" = "csv"): Promise<Blob> {
    const token = this.getToken()
    const response = await fetch(
      `${this.baseUrl}/api/v1/activation-codes/batch/${batchId}/export?format=${format}`,
      {
        method: "POST",
        headers: { Authorization: `Bearer ${token}` },
      }
    )
    if (!response.ok) throw { message: "Export failed", statusCode: response.status }
    return response.blob()
  }

  async revokeCode(codeId: string): Promise<void> {
    return this.request(`/api/v1/activation-codes/${codeId}/revoke`, {
      method: "PATCH",
    })
  }

  async revokeBatch(batchId: string): Promise<void> {
    return this.request(`/api/v1/activation-codes/batch/${batchId}/revoke`, {
      method: "PATCH",
    })
  }

  // ── Security ──
  async getSecurityFlags(params: {
    studentId?: string
    flagType?: string
  } = {}): Promise<SecurityFlag[]> {
    const qs = new URLSearchParams()
    if (params.studentId) qs.set("studentId", params.studentId)
    if (params.flagType) qs.set("flagType", params.flagType)
    return this.request(`/api/v1/security/flags?${qs}`)
  }

  async reviewSecurityFlag(
    flagId: string,
    actionTaken: SecurityFlag["actionTaken"]
  ): Promise<void> {
    return this.request(`/api/v1/security/flags/${flagId}/review`, {
      method: "PATCH",
      body: JSON.stringify({ actionTaken }),
    })
  }
}

export const api = new ApiClient(API_URL)
