import { useEffect, useMemo, useState } from 'react'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { getAllSubjects, getTeachingSubjects, searchAudienceUsers } from '@/services/notifications.api'
import type {
  AudienceDto,
  AudienceSubjectOption,
  AudienceUserOption,
  AudienceKind,
} from '@/types/notifications'
import type { UserRole } from '@/types'

type AudiencePickerProps = {
  value: AudienceDto
  onChange: (value: AudienceDto) => void
  role: UserRole | null
}

const ADMIN_TABS: Array<{ kind: AudienceKind; label: string }> = [
  { kind: 'all', label: 'All users' },
  { kind: 'user-list', label: 'Specific users' },
  { kind: 'subject', label: 'Subject' },
]

export function AudiencePicker({ value, onChange, role }: AudiencePickerProps) {
  const [subjects, setSubjects] = useState<AudienceSubjectOption[]>([])
  const [search, setSearch] = useState('')
  const [results, setResults] = useState<AudienceUserOption[]>([])
  const [loadingUsers, setLoadingUsers] = useState(false)

  const activeKind: AudienceKind = role === 'teacher' ? 'subject' : value.kind
  const selectedUserIds = useMemo(() => value.userIds ?? [], [value.userIds])
  const visibleResults = role === 'admin' && activeKind === 'user-list' && search.trim() ? results : []

  const selectedUsers = useMemo(
    () =>
      selectedUserIds
        .map((id) => results.find((user) => user.id === id) ?? { id, name: id, email: '', role: 'student' as const })
        .slice(0, 1000),
    [results, selectedUserIds],
  )

  useEffect(() => {
    const loadSubjects = async () => {
      const nextSubjects = role === 'teacher' ? await getTeachingSubjects() : await getAllSubjects()
      setSubjects(nextSubjects)
    }

    void loadSubjects()
  }, [role])

  useEffect(() => {
    if (role !== 'admin' || activeKind !== 'user-list' || !search.trim()) {
      return
    }

    const timeout = window.setTimeout(async () => {
      setLoadingUsers(true)
      try {
        const nextResults = await searchAudienceUsers(search.trim(), 20)
        setResults(nextResults)
      } finally {
        setLoadingUsers(false)
      }
    }, 350)

    return () => window.clearTimeout(timeout)
  }, [activeKind, role, search])

  const setKind = (kind: AudienceKind) => {
    if (kind === 'all') {
      onChange({ kind: 'all' })
      return
    }

    if (kind === 'user-list') {
      onChange({ kind: 'user-list', userIds: [] })
      return
    }

    onChange({ kind: 'subject', subjectId: value.subjectId })
  }

  const toggleUser = (user: AudienceUserOption) => {
    const ids = new Set(selectedUserIds)
    if (ids.has(user.id)) {
      ids.delete(user.id)
    } else if (ids.size < 1000) {
      ids.add(user.id)
    }

    onChange({ kind: 'user-list', userIds: Array.from(ids) })
  }

  const removeUser = (userId: string) => {
    onChange({ kind: 'user-list', userIds: selectedUserIds.filter((id) => id !== userId) })
  }

  return (
    <div className="space-y-3 rounded-xl border border-stone-200 bg-white/80 p-4">
      <div className="space-y-1.5">
        <Label className="text-sm font-medium text-stone-700">Audience</Label>
        {role === 'teacher' ? (
          <div className="rounded-full border border-teal-200 bg-teal-50 px-3 py-2 text-sm text-teal-800">
            Teachers can send to their own subjects only.
          </div>
        ) : (
          <div className="flex flex-wrap gap-2">
            {ADMIN_TABS.map((tab) => (
              <Button
                key={tab.kind}
                type="button"
                variant={activeKind === tab.kind ? 'default' : 'outline'}
                className={activeKind === tab.kind ? 'rounded-full bg-teal-700 hover:bg-teal-800' : 'rounded-full'}
                onClick={() => setKind(tab.kind)}
              >
                {tab.label}
              </Button>
            ))}
          </div>
        )}
      </div>

      {activeKind === 'subject' && (
        <div className="space-y-1.5">
          <Label className="text-sm font-medium text-stone-700">Subject</Label>
          <Select
            value={value.subjectId}
            onValueChange={(subjectId) => onChange({ kind: 'subject', subjectId })}
          >
            <SelectTrigger className="border-stone-200 bg-white focus:ring-teal-600">
              <SelectValue placeholder="Select a subject" />
            </SelectTrigger>
            <SelectContent>
              {subjects.map((subject) => (
                <SelectItem key={subject.id} value={subject.id}>
                  {subject.title}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      )}

      {activeKind === 'user-list' && role === 'admin' && (
        <div className="space-y-3">
          <div className="space-y-1.5">
            <Label className="text-sm font-medium text-stone-700">Search users</Label>
            <Input
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search by name or email"
              className="border-stone-200 bg-white focus-visible:ring-teal-600"
            />
          </div>

          {selectedUsers.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {selectedUsers.map((user) => (
                <button
                  key={user.id}
                  type="button"
                  className="rounded-full border border-stone-200 bg-stone-50 px-3 py-1 text-xs text-stone-700"
                  onClick={() => removeUser(user.id)}
                >
                  {user.name} x
                </button>
              ))}
            </div>
          )}

          <div className="max-h-56 space-y-2 overflow-auto rounded-lg border border-stone-100 bg-stone-50 p-2">
            {loadingUsers && <p className="px-2 py-1 text-xs text-stone-500">Searching...</p>}
            {!loadingUsers && visibleResults.length === 0 && (
              <p className="px-2 py-1 text-xs text-stone-500">Search to find users.</p>
            )}
            {visibleResults.map((user) => {
              const selected = selectedUserIds.includes(user.id)
              return (
                <button
                  key={user.id}
                  type="button"
                  className={`flex w-full items-center justify-between rounded-lg px-3 py-2 text-left text-sm ${
                    selected ? 'bg-teal-100 text-teal-900' : 'bg-white text-stone-700'
                  }`}
                  onClick={() => toggleUser(user)}
                >
                  <span>
                    <span className="block font-medium">{user.name}</span>
                    <span className="block text-xs text-stone-500">{user.email}</span>
                  </span>
                  <span className="text-xs uppercase">{user.role}</span>
                </button>
              )
            })}
          </div>
        </div>
      )}
    </div>
  )
}
