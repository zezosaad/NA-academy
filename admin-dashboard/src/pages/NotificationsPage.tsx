import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs"
import { NotificationsHistoryPage } from "./NotificationsHistoryPage"
import { NotificationsSendPage } from "./NotificationsSendPage"
import { Bell } from "lucide-react"

export function NotificationsPage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <Bell className="h-5 w-5 text-teal-700" />
        <h1 className="font-[Fraunces] text-2xl font-semibold text-stone-900">Notifications</h1>
      </div>

      <Tabs defaultValue="send">
        <TabsList className="border border-stone-200 bg-stone-50">
          <TabsTrigger value="send">Send</TabsTrigger>
          <TabsTrigger value="history">History</TabsTrigger>
        </TabsList>

        <TabsContent value="send" className="mt-6">
          <NotificationsSendPage />
        </TabsContent>

        <TabsContent value="history" className="mt-6">
          <NotificationsHistoryPage />
        </TabsContent>
      </Tabs>
    </div>
  )
}
