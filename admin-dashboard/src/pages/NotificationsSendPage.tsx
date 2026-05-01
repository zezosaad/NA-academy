import { NotificationComposer } from "@/components/NotificationComposer"
import type { NotificationResponseDto } from "@/types/notifications"
import { useState } from "react"

export function NotificationsSendPage() {
  const [lastSent, setLastSent] = useState<NotificationResponseDto | null>(null)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-[Fraunces] text-2xl font-semibold text-stone-900">
          Send Notification
        </h1>
        <p className="mt-1 text-sm text-stone-500">
          Compose and send a push notification to all users, a specific user list, or a subject audience.
        </p>
      </div>

      <NotificationComposer
        onSent={(notification) => setLastSent(notification)}
      />

      {lastSent && (
        <div className="mx-auto max-w-2xl rounded-lg border border-stone-100 bg-white px-4 py-3 text-xs text-stone-400">
          Last sent: <span className="font-medium text-stone-600">{lastSent.title}</span> &bull;{" "}
          {lastSent.stats.total} recipient{lastSent.stats.total !== 1 ? "s" : ""} &bull;{" "}
          {new Date(lastSent.createdAt).toLocaleTimeString()}
        </div>
      )}
    </div>
  )
}
