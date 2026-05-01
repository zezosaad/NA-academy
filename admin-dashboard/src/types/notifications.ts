// Canonical notification types — mirrors contracts/notifications.md
// Do NOT create parallel ad-hoc types elsewhere in the dashboard.

export type AudienceKind = 'all' | 'user-list' | 'subject'

export interface AudienceDto {
  kind: AudienceKind
  /** Required when kind = 'user-list' */
  userIds?: string[]
  /** Required when kind = 'subject' */
  subjectId?: string
}

export interface CreateNotificationDto {
  title: string
  body: string
  data?: Record<string, string>
  audience: AudienceDto
}

export interface NotificationStatsDto {
  total: number
  delivered: number
  failed: number
  read: number
}

export interface AudienceResponseDto {
  kind: AudienceKind
  userIds?: string[]
  subjectId?: string
  resolvedRecipientCount: number
}

export interface NotificationResponseDto {
  id: string
  title: string
  body: string
  data?: Record<string, string>
  senderId: string
  senderName: string
  senderRole: 'admin' | 'teacher'
  audience: AudienceResponseDto
  stats: NotificationStatsDto
  createdAt: string
}

export interface InboxItemDto {
  id: string
  notificationId: string
  title: string
  body: string
  data?: Record<string, string>
  state: 'pending' | 'delivered' | 'failed'
  readAt?: string
  deliveredAt?: string
  createdAt: string
}

export interface InboxResponseDto {
  items: InboxItemDto[]
  unreadCount: number
  hasMore: boolean
  nextCursor?: string
}

export interface RecipientStateDto {
  userId: string
  userName: string
  state: 'pending' | 'delivered' | 'failed'
  failureReason?: string
  deliveredAt?: string
  readAt?: string
}

export interface NotificationDetailResponseDto {
  id: string
  title: string
  body: string
  data?: Record<string, string>
  senderId: string
  senderName: string
  senderRole: 'admin' | 'teacher'
  audience: AudienceResponseDto
  stats: NotificationStatsDto
  createdAt: string
  recipients?: RecipientStateDto[]
  recipientsArchived?: boolean
  recipientsArchivedAt?: string
}

export interface NotificationListQueryDto {
  q?: string
  audienceKind?: AudienceKind
  subjectId?: string
  before?: string
  limit?: number
}

export interface AudienceSubjectOption {
  id: string
  title: string
}

export interface AudienceUserOption {
  id: string
  name: string
  email: string
  role: 'student' | 'teacher' | 'admin'
}
