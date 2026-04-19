import { useState, useEffect, useCallback, useRef } from "react"
import { api } from "@/services/api"
import type { DashboardResponse } from "@/types"

interface DashboardState {
  data: DashboardResponse | null
  loading: boolean
  error: string | null
  lastUpdated: Date | null
}

const REFRESH_INTERVAL = 60000 // 60 seconds

export function useDashboard() {
  const [state, setState] = useState<DashboardState>({
    data: null,
    loading: true,
    error: null,
    lastUpdated: null,
  })
  const [isRefreshing, setIsRefreshing] = useState(false)
  const [isRefreshQueued, setIsRefreshQueued] = useState(false)
  const inFlightRef = useRef(false)
  const queuedManualRefreshRef = useRef(false)

  const fetchDashboard = useCallback(async (trigger: "initial" | "auto" | "manual" = "initial") => {
    if (inFlightRef.current) {
      if (trigger === "manual") {
        queuedManualRefreshRef.current = true
        setIsRefreshQueued(true)
      }
      return
    }

    inFlightRef.current = true
    if (trigger === "manual") {
      setIsRefreshing(true)
    }

    try {
      const data = await api.getDashboard()
      setState((prev) => ({
        ...prev,
        data,
        loading: false,
        error: null,
        lastUpdated: new Date(),
      }))
    } catch (err) {
      setState((prev) => ({
        ...prev,
        loading: false,
        error: err instanceof Error ? err.message : "Failed to fetch dashboard",
      }))
    } finally {
      inFlightRef.current = false
      if (trigger === "manual") {
        setIsRefreshing(false)
      }

      if (queuedManualRefreshRef.current) {
        queuedManualRefreshRef.current = false
        setIsRefreshQueued(false)
        void fetchDashboard("manual")
      }
    }
  }, [])

  useEffect(() => {
    void fetchDashboard("initial")
  }, [fetchDashboard])

  useEffect(() => {
    const intervalId = setInterval(() => {
      void fetchDashboard("auto")
    }, REFRESH_INTERVAL)

    return () => clearInterval(intervalId)
  }, [fetchDashboard])

  const refresh = useCallback(() => {
    void fetchDashboard("manual")
  }, [fetchDashboard])

  return {
    ...state,
    refresh,
    isRefreshing,
    isRefreshQueued,
  }
}
