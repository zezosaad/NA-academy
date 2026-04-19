import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { cn } from "@/lib/utils"

interface DashboardCardProps {
  title: string
  value: number | string
  icon?: React.ReactNode
  className?: string
}

export function DashboardCard({
  title,
  value,
  icon,
  className,
}: DashboardCardProps) {
  const displayValue =
    typeof value === "number" && value >= 1000
      ? new Intl.NumberFormat().format(value)
      : value

  return (
    <Card className={cn("", className)}>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        {icon && <div className="h-4 w-4 text-muted-foreground">{icon}</div>}
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-bold">{displayValue}</div>
      </CardContent>
    </Card>
  )
}
