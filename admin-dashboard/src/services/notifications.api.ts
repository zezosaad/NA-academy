import type {
  CreateNotificationDto,
  NotificationResponseDto,
  NotificationDetailResponseDto,
  NotificationListQueryDto,
} from '@/types/notifications'

const API_URL = import.meta.env.VITE_API_URL ?? ''

function getToken(): string {
  return localStorage.getItem('auth_token') ?? ''
}

async function apiFetch<T>(endpoint: string, init: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${getToken()}`,
    ...((init.headers as Record<string, string>) ?? {}),
  }
  if (!(init.body instanceof FormData)) {
    headers['Content-Type'] = 'application/json'
  }

  const response = await fetch(`${API_URL}${endpoint}`, { ...init, headers })

  if (!response.ok) {
    let message = `HTTP error ${response.status}`
    try {
      const body = await response.json()
      message = body?.message ?? message
    } catch {
      // ignore
    }
    throw new Error(message)
  }

  if (response.status === 204) return undefined as T
  const json = await response.json()
  return (json?.data ?? json) as T
}

/**
 * Send a push notification. Generates a fresh UUID v4 idempotency key per call.
 */
export async function sendNotification(
  dto: CreateNotificationDto,
): Promise<NotificationResponseDto> {
  return apiFetch<NotificationResponseDto>('/api/v1/notifications', {
    method: 'POST',
    headers: { 'Idempotency-Key': crypto.randomUUID() },
    body: JSON.stringify(dto),
  })
}

/**
 * List notification history (admin/teacher).
 */
export async function listNotifications(
  query: NotificationListQueryDto = {},
): Promise<NotificationResponseDto[]> {
  const params = new URLSearchParams()
  if (query.q) params.set('q', query.q)
  if (query.audienceKind) params.set('audienceKind', query.audienceKind)
  if (query.subjectId) params.set('subjectId', query.subjectId)
  if (query.before) params.set('before', query.before)
  if (query.limit != null) params.set('limit', String(query.limit))
  const qs = params.toString()
  return apiFetch<NotificationResponseDto[]>(
    `/api/v1/notifications${qs ? `?${qs}` : ''}`,
  )
}

/**
 * Get notification detail by ID.
 */
export async function getNotification(id: string): Promise<NotificationDetailResponseDto> {
  return apiFetch<NotificationDetailResponseDto>(`/api/v1/notifications/${id}`)
}
