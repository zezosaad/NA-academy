import type { DashboardResponse, ApiError } from "@/types"

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
    options: RequestInit = {}
  ): Promise<T> {
    const token = this.getToken()

    const headers: HeadersInit = {
      "Content-Type": "application/json",
      ...options.headers,
    }

    if (token) {
      ;(headers as Record<string, string>)["Authorization"] = `Bearer ${token}`
    }

    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      ...options,
      headers,
    })

    if (!response.ok) {
      if (response.status === 401) {
        localStorage.removeItem("auth_token")
        window.location.href = "/login"
      }
      const error: ApiError = {
        message:
          response.status === 401
            ? "Unauthorized (401) - Please sign in again"
            : `HTTP error ${response.status}`,
        statusCode: response.status,
      }
      throw error
    }

    return response.json()
  }

  async getDashboard(): Promise<DashboardResponse> {
    return this.request<DashboardResponse>("/api/admin/dashboard")
  }

  async updateSecurityFlag(
    flagId: string,
    action: "REVIEWED" | "DISMISSED"
  ): Promise<void> {
    return this.request(`/api/admin/security-flags/${flagId}`, {
      method: "PATCH",
      body: JSON.stringify({ action }),
    })
  }
}

export const api = new ApiClient(API_URL)
