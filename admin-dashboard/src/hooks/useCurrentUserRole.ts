import { useMemo } from 'react'

import type { UserRole } from '@/types'

function readRoleFromToken(): UserRole | null {
  const token = localStorage.getItem('auth_token')
  if (!token) return null

  try {
    const payload = JSON.parse(atob(token.split('.')[1])) as { role?: UserRole }
    return payload.role ?? null
  } catch {
    return null
  }
}

export function useCurrentUserRole(): UserRole | null {
  return useMemo(() => readRoleFromToken(), [])
}
