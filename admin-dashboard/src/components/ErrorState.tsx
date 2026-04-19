import { AlertCircle, RefreshCw } from "lucide-react"
import { Button } from "@/components/ui/button"
import { clearToken } from "@/lib/auth"

interface ErrorStateProps {
  message: string
  onRetry?: () => void
  authError?: boolean
}

export function ErrorState({ message, onRetry, authError = false }: ErrorStateProps) {
  const handleLoginRedirect = () => {
    clearToken()
    window.location.reload()
  }

  return (
    <div className="flex min-h-[400px] items-center justify-center">
      <div className="flex flex-col items-center gap-4 text-center">
        <AlertCircle className="h-10 w-10 text-destructive" />
        <p className="text-sm text-muted-foreground">{message}</p>
        {authError ? (
          <Button onClick={handleLoginRedirect} variant="default" size="sm">
            Go to Login
          </Button>
        ) : null}
        {onRetry && (
          <Button onClick={onRetry} variant="outline" size="sm">
            <RefreshCw className="mr-2 h-4 w-4" />
            Try Again
          </Button>
        )}
      </div>
    </div>
  )
}
