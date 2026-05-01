import { LoadingSpinner } from "@/components/ui/loading-spinner"

interface LoadingStateProps {
  message?: string
}

export function LoadingState({ message = "Loading dashboard..." }: LoadingStateProps = {}) {
  return (
    <div className="flex min-h-[400px] items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <LoadingSpinner />
        <p className="text-sm text-muted-foreground">{message}</p>
      </div>
    </div>
  )
}
