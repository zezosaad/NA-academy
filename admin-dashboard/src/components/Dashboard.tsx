import { RefreshCw } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { StatsGrid } from "./StatsGrid"
import { ActivationList } from "./ActivationList"
import { SecurityFlagList } from "./SecurityFlagList"
import { LoadingState } from "./LoadingState"
import { ErrorState } from "./ErrorState"
import { useDashboard } from "@/hooks/useDashboard"
import { api } from "@/services/api"

export function Dashboard() {
  const { data, loading, error, lastUpdated, refresh, isRefreshing, isRefreshQueued } = useDashboard()

  const handleDismiss = async (flagId: string) => {
    await api.updateSecurityFlag(flagId, "REVIEWED")
    refresh()
  }

  if (loading) {
    return <LoadingState />
  }

  if (error) {
    return (
      <ErrorState
        message={error}
        onRetry={refresh}
        authError={error.toLowerCase().includes("401") || error.toLowerCase().includes("unauthorized")}
      />
    )
  }

  if (!data) {
    return <ErrorState message="No data available" onRetry={refresh} />
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
          {lastUpdated && (
            <p className="text-sm text-muted-foreground">
              Last updated: {lastUpdated.toLocaleTimeString()}
            </p>
          )}
        </div>
        <Button
          onClick={refresh}
          variant="outline"
          size="sm"
        >
          <RefreshCw
            className={`mr-2 h-4 w-4 ${isRefreshing ? "animate-spin" : ""}`}
          />
          {isRefreshing ? "Refreshing..." : isRefreshQueued ? "Queued..." : "Refresh"}
        </Button>
      </div>

      <StatsGrid data={data} />

      <Card>
        <CardHeader>
          <CardTitle>Recent Activations</CardTitle>
        </CardHeader>
        <CardContent>
          <ActivationList activations={data.recentActivations} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Security Flags</CardTitle>
        </CardHeader>
        <CardContent>
          <SecurityFlagList
            flags={data.securityFlags}
            onDismiss={handleDismiss}
          />
        </CardContent>
      </Card>
    </div>
  )
}
