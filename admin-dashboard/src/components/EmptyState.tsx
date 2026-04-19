import { cn } from "@/lib/utils"

interface EmptyStateProps {
  title: string
  description?: string
  className?: string
}

export function EmptyState({
  title,
  description,
  className,
}: EmptyStateProps) {
  return (
    <div className={cn("flex flex-col items-center gap-2 py-8", className)}>
      <p className="text-sm font-medium">{title}</p>
      {description && (
        <p className="text-sm text-muted-foreground">{description}</p>
      )}
    </div>
  )
}