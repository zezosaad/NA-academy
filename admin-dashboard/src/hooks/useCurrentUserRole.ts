import { useMemo } from 'react'

import type { UserRole } from '@/types'

const VALID_USER_ROLES = new Set<UserRole>(['student', 'teacher', 'admin'])

function isUserRole(value: unknown): value is UserRole {
  return typeof value === 'string' && VALID_USER_ROLES.has(value as UserRole)
}

function readRoleFromToken(): UserRole | null {
  const token = localStorage.getItem('auth_token')
  if (!token) return null

  try {
    const payload = JSON.parse(atob(token.split('.')[1])) as { role?: unknown }
    return isUserRole(payload.role) ? payload.role : null
  } catch {
    return null
  }
}

export function useCurrentUserRole(): UserRole | null {
  return useMemo(() => readRoleFromToken(), [])
}
