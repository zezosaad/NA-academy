import { Users, BookOpen, Key, ShieldAlert } from "lucide-react"
import { DashboardCard } from "./DashboardCard"
import type { DashboardResponse } from "@/types"

interface StatsGridProps {
  data: DashboardResponse
}

export function StatsGrid({ data }: StatsGridProps) {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <DashboardCard
        title="Active Students"
        value={data.activeStudentsNow}
        icon={<Users className="h-4 w-4" />}
      />
      <DashboardCard
        title="Ongoing Exams"
        value={data.ongoingExams}
        icon={<BookOpen className="h-4 w-4" />}
      />
      <DashboardCard
        title="Recent Activations"
        value={data.recentActivations.length}
        icon={<Key className="h-4 w-4" />}
      />
      <DashboardCard
        title="Security Flags"
        value={data.securityFlags.length}
        icon={<ShieldAlert className="h-4 w-4" />}
      />
    </div>
  )
}