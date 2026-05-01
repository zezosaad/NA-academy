import { useEffect, useMemo, useRef, useState } from 'react'

import { NotificationDetailDrawer } from '@/components/NotificationDetailDrawer'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { getAllSubjects, listNotifications } from '@/services/notifications.api'
import type { NotificationResponseDto } from '@/types/notifications'

export function NotificationsHistoryPage() {
  const [items, setItems] = useState<NotificationResponseDto[]>([])
  const [nextCursor, setNextCursor] = useState<string | undefined>()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [searchDraft, setSearchDraft] = useState('')
  const [query, setQuery] = useState('')
  const [selected, setSelected] = useState<NotificationResponseDto | null>(null)
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [subjectTitles, setSubjectTitles] = useState<Record<string, string>>({})
  const requestSeq = useRef(0)

  const openDetails = (notification: NotificationResponseDto) => {
    setSelected(notification)
    setDrawerOpen(true)
  }

  useEffect(() => {
    const timeout = window.setTimeout(() => setQuery(searchDraft.trim()), 350)
    return () => window.clearTimeout(timeout)
  }, [searchDraft])

  useEffect(() => {
    const loadSubjects = async () => {
      try {
        const subjects = await getAllSubjects()
        setSubjectTitles(Object.fromEntries(subjects.map((subject) => [subject.id, subject.title])))
      } catch {
        setSubjectTitles({})
      }
    }

    void loadSubjects()
  }, [])

  useEffect(() => {
    const requestId = ++requestSeq.current
    let cancelled = false

    const load = async () => {
      setLoading(true)
      setError(null)
      try {
        const response = await listNotifications({ q: query || undefined, limit: 20 })
        if (!cancelled && requestSeq.current === requestId) {
          setItems(response.items)
          setNextCursor(response.nextCursor)
        }
      } catch (err) {
        if (!cancelled && requestSeq.current === requestId) {
          setError(err instanceof Error ? err.message : 'Failed to load notifications')
        }
      } finally {
        if (!cancelled && requestSeq.current === requestId) {
          setLoading(false)
        }
      }
    }

    void load()

    return () => {
      cancelled = true
    }
  }, [query])

  const loadMore = async () => {
    if (!nextCursor || loading) return
    const requestId = ++requestSeq.current
    setLoading(true)
    try {
      const response = await listNotifications({ q: query || undefined, before: nextCursor, limit: 20 })
      if (requestSeq.current === requestId) {
        setItems((current) => [...current, ...response.items])
        setNextCursor(response.nextCursor)
      }
    } catch (err) {
      if (requestSeq.current === requestId) {
        setError(err instanceof Error ? err.message : 'Failed to load more notifications')
      }
    } finally {
      if (requestSeq.current === requestId) {
        setLoading(false)
      }
    }
  }

  const rows = useMemo(() => items, [items])

  const audienceLabel = (notification: NotificationResponseDto) => {
    if (notification.audience.kind === 'all') return `All users - ${notification.audience.resolvedRecipientCount} recipients`
    if (notification.audience.kind === 'user-list') return `${notification.audience.resolvedRecipientCount} specific users`
    const subjectId = notification.audience.subjectId
    return `Subject: ${subjectId ? (subjectTitles[subjectId] ?? subjectId) : 'Unknown'} - ${notification.audience.resolvedRecipientCount} recipients`
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <Input
          value={searchDraft}
          onChange={(event) => setSearchDraft(event.target.value)}
          placeholder="Search notifications"
          className="max-w-md border-stone-200 bg-white"
        />
      </div>

      <div className="rounded-xl border border-stone-200 bg-white">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Title</TableHead>
              <TableHead>Audience</TableHead>
              <TableHead>Sender</TableHead>
              <TableHead>Sent at</TableHead>
              <TableHead>Delivered / Total</TableHead>
              <TableHead>Read</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {rows.map((notification) => (
              <TableRow key={notification.id}>
                <TableCell className="font-medium text-stone-900">{notification.title}</TableCell>
                <TableCell className="text-stone-600">{audienceLabel(notification)}</TableCell>
                <TableCell>{notification.senderName || notification.senderId}</TableCell>
                <TableCell>{new Date(notification.createdAt).toLocaleString()}</TableCell>
                <TableCell>{notification.stats.delivered} / {notification.stats.total}</TableCell>
                <TableCell>
                  <div className="flex items-center justify-between gap-3">
                    <span>{notification.stats.read}</span>
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      aria-label={`Open details for notification ${notification.id}`}
                      onClick={() => openDetails(notification)}
                    >
                      Open details
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      {error && <p className="text-sm text-red-600">{error}</p>}
      {loading && <p className="text-sm text-stone-500">Loading...</p>}
      {nextCursor && !loading && (
        <Button type="button" variant="outline" className="rounded-full" onClick={loadMore}>
          Load more
        </Button>
      )}

      <NotificationDetailDrawer
        notification={selected}
        open={drawerOpen}
        onOpenChange={setDrawerOpen}
        subjectTitles={subjectTitles}
      />
    </div>
  )
}
