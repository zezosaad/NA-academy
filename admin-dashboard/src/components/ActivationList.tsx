import { format } from "date-fns"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { EmptyState } from "./EmptyState"
import type { Activation } from "@/types"

interface ActivationListProps {
  activations: Activation[]
}

export function ActivationList({ activations }: ActivationListProps) {
  if (activations.length === 0) {
    return (
      <EmptyState
        title="No recent activations"
        description="There are no activation codes that have been used recently."
      />
    )
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Student</TableHead>
          <TableHead>Email</TableHead>
          <TableHead>Activated At</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {activations.map((activation) => (
          <TableRow key={activation._id}>
            <TableCell className="font-medium">
              {activation.activatedBy.name}
            </TableCell>
            <TableCell className="text-muted-foreground">
              {activation.activatedBy.email}
            </TableCell>
            <TableCell className="text-muted-foreground">
              {format(new Date(activation.activatedAt), "MMM d, yyyy 'at' h:mm a")}
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  )
}