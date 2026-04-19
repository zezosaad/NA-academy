import { useState } from "react"
import { format } from "date-fns"
import { ShieldAlert, Check } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { EmptyState } from "./EmptyState"
import type { SecurityFlag } from "@/types"

interface SecurityFlagListProps {
  flags: SecurityFlag[]
  onDismiss: (flagId: string) => Promise<void>
}

export function SecurityFlagList({ flags, onDismiss }: SecurityFlagListProps) {
  const [dismissing, setDismissing] = useState<string | null>(null)

  const handleDismiss = async (flagId: string) => {
    setDismissing(flagId)
    try {
      await onDismiss(flagId)
    } finally {
      setDismissing(null)
    }
  }

  if (flags.length === 0) {
    return (
      <EmptyState
        title="No pending security flags"
        description="There are no security flags that need review."
      />
    )
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Student</TableHead>
          <TableHead>Description</TableHead>
          <TableHead>Created</TableHead>
          <TableHead>Status</TableHead>
          <TableHead className="text-right">Actions</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {flags.map((flag) => (
          <TableRow key={flag._id}>
            <TableCell className="font-medium">
              {flag.studentId.name}
              <p className="text-xs text-muted-foreground">
                {flag.studentId.email}
              </p>
            </TableCell>
            <TableCell>{flag.description}</TableCell>
            <TableCell className="text-muted-foreground">
              {format(new Date(flag.createdAt), "MMM d, yyyy 'at' h:mm a")}
            </TableCell>
            <TableCell>
              {flag.actionTaken === "NONE" ? (
                <Badge variant="destructive">
                  <ShieldAlert className="mr-1 h-3 w-3" />
                  Pending
                </Badge>
              ) : (
                <Badge variant="secondary">
                  <Check className="mr-1 h-3 w-3" />
                  Reviewed
                </Badge>
              )}
            </TableCell>
            <TableCell className="text-right">
              {flag.actionTaken === "NONE" && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleDismiss(flag._id)}
                  disabled={dismissing === flag._id}
                >
                  {dismissing === flag._id ? "Dismissing..." : "Dismiss"}
                </Button>
              )}
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  )
}