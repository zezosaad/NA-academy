import { useEffect, useState } from 'react'

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { getNotification } from '@/services/notifications.api'
import type { NotificationDetailResponseDto, NotificationResponseDto } from '@/types/notifications'

type NotificationDetailDrawerProps = {
  notification: NotificationResponseDto | null
  open: boolean
  onOpenChange: (open: boolean) => void
  subjectTitles: Record<string, string>
}

export function NotificationDetailDrawer({
  notification,
  open,
  onOpenChange,
  subjectTitles,
}: NotificationDetailDrawerProps) {
  const [detail, setDetail] = useState<NotificationDetailResponseDto | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!open || !notification) {
      return
    }

    const load = async () => {
      setLoading(true)
      setError(null)
      try {
        setDetail(await getNotification(notification.id))
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load notification details')
      } finally {
        setLoading(false)
      }
    }

    void load()
  }, [notification, open])

  const active = detail ?? notification
  const archived = detail?.recipientsArchived === true
  const recipients = detail?.recipients ?? []
  const audienceLabel = active
    ? active.audience.kind === 'all'
      ? 'All users'
      : active.audience.kind === 'user-list'
        ? `${active.audience.resolvedRecipientCount} specific users`
        : `Subject: ${active.audience.subjectId ? (subjectTitles[active.audience.subjectId] ?? active.audience.subjectId) : 'Unknown'}`
    : ''

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl border-stone-200 bg-[#FAF7F2]">
        <DialogHeader>
          <DialogTitle className="font-[Fraunces] text-2xl text-stone-900">
            {active?.title ?? 'Notification'}
          </DialogTitle>
          <DialogDescription className="text-stone-500">
            {active ? new Date(active.createdAt).toLocaleString() : ''}
          </DialogDescription>
        </DialogHeader>

        {loading && <p className="text-sm text-stone-500">Loading details...</p>}
        {error && <p className="text-sm text-red-600">{error}</p>}

        {active && (
          <div className="space-y-5 text-sm text-stone-700">
            <div className="rounded-xl border border-stone-200 bg-white p-4">
              <p className="whitespace-pre-wrap leading-7">{active.body}</p>
            </div>

            {active.data && Object.keys(active.data).length > 0 && (
              <div className="rounded-xl border border-stone-200 bg-white p-4">
                <h3 className="mb-2 font-medium text-stone-900">Payload</h3>
                <pre className="overflow-auto text-xs text-stone-600">{JSON.stringify(active.data, null, 2)}</pre>
              </div>
            )}

            <div className="grid gap-3 rounded-xl border border-stone-200 bg-white p-4 md:grid-cols-2">
              <div>
                <p className="text-xs uppercase tracking-wide text-stone-400">Audience</p>
                <p className="mt-1 font-medium text-stone-900">{audienceLabel}</p>
              </div>
              <div>
                <p className="text-xs uppercase tracking-wide text-stone-400">Sender</p>
                <p className="mt-1 font-medium text-stone-900">{active.senderName || active.senderId}</p>
              </div>
              <div>
                <p className="text-xs uppercase tracking-wide text-stone-400">Delivered / Total</p>
                <p className="mt-1 font-medium text-stone-900">{active.stats.delivered} / {active.stats.total}</p>
              </div>
              <div>
                <p className="text-xs uppercase tracking-wide text-stone-400">Read</p>
                <p className="mt-1 font-medium text-stone-900">{active.stats.read}</p>
              </div>
            </div>

            {archived ? (
              <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-amber-900">
                Archived: per-recipient delivery details cleared on{' '}
                {detail?.recipientsArchivedAt ? new Date(detail.recipientsArchivedAt).toLocaleDateString() : 'schedule expiry'}.
              </div>
            ) : recipients.length > 0 ? (
              <div className="max-h-80 overflow-auto rounded-xl border border-stone-200 bg-white p-4">
                <h3 className="mb-3 font-medium text-stone-900">Recipients</h3>
                <div className="space-y-2">
                  {recipients.map((recipient) => (
                    <div key={recipient.userId} className="flex items-center justify-between rounded-lg border border-stone-100 px-3 py-2">
                      <span className="font-medium text-stone-800">{recipient.userName}</span>
                      <span className="text-xs uppercase text-stone-500">{recipient.state}</span>
                    </div>
                  ))}
                </div>
              </div>
            ) : null}
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}
