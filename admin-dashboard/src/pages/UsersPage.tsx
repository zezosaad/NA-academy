import { useState, useEffect, useCallback } from "react"
import { Search, RotateCw, Smartphone, Ban, CheckCircle, XCircle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { LoadingState } from "@/components/LoadingState"
import { EmptyState } from "@/components/EmptyState"
import { useAppModal } from "@/components/AppModalProvider"
import { api } from "@/services/api"
import type { User, UserStatus } from "@/types"
import { format } from "date-fns"

export function UsersPage() {
  const { showError } = useAppModal()
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState("")
  const [roleFilter, setRoleFilter] = useState<string>("all")
  const [statusFilter, setStatusFilter] = useState<string>("all")

  const [actionDialog, setActionDialog] = useState<{
    user: User
    action: "active" | "suspended" | "banned" | "device-reset"
  } | null>(null)
  const [actionLoading, setActionLoading] = useState(false)

  const limit = 20

  const fetchUsers = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.getUsers({
        page,
        limit,
        search: search || undefined,
        role: roleFilter !== "all" ? roleFilter : undefined,
        status: statusFilter !== "all" ? statusFilter : undefined,
      })
      setUsers(res.data)
      setTotal(res.total)
    } catch {
      // handled by error state
    } finally {
      setLoading(false)
    }
  }, [page, search, roleFilter, statusFilter])

  useEffect(() => {
    fetchUsers()
  }, [fetchUsers])

  // Reset page on filter change
  useEffect(() => {
    setPage(1)
  }, [search, roleFilter, statusFilter])

  const handleAction = async () => {
    if (!actionDialog) return
    setActionLoading(true)
    try {
      if (actionDialog.action === "device-reset") {
        await api.resetUserDevice(actionDialog.user._id)
      } else {
        await api.updateUserStatus(actionDialog.user._id, actionDialog.action as UserStatus)
      }
      setActionDialog(null)
      fetchUsers()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Action failed")
    } finally {
      setActionLoading(false)
    }
  }

  const statusBadge = (status: UserStatus) => {
    switch (status) {
      case "active":
        return <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">Active</Badge>
      case "suspended":
        return <Badge variant="secondary">Suspended</Badge>
      case "banned":
        return <Badge variant="destructive">Banned</Badge>
    }
  }

  const roleBadge = (role: string) => {
    switch (role) {
      case "admin":
        return <Badge className="bg-purple-500/10 text-purple-600 border-purple-200">Admin</Badge>
      case "teacher":
        return <Badge className="bg-blue-500/10 text-blue-600 border-blue-200">Teacher</Badge>
      default:
        return <Badge variant="outline">Student</Badge>
    }
  }

  const totalPages = Math.ceil(total / limit)

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search by name or email..."
            className="pl-9"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <Select value={roleFilter} onValueChange={setRoleFilter}>
          <SelectTrigger className="w-[130px]">
            <SelectValue placeholder="Role" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Roles</SelectItem>
            <SelectItem value="student">Student</SelectItem>
            <SelectItem value="teacher">Teacher</SelectItem>
            <SelectItem value="admin">Admin</SelectItem>
          </SelectContent>
        </Select>
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-[140px]">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="active">Active</SelectItem>
            <SelectItem value="suspended">Suspended</SelectItem>
            <SelectItem value="banned">Banned</SelectItem>
          </SelectContent>
        </Select>
        <span className="text-sm text-muted-foreground">{total} users</span>
      </div>

      {/* Table */}
      {loading ? (
        <LoadingState />
      ) : users.length === 0 ? (
        <EmptyState title="No users found" description="Try adjusting your filters." />
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Role</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Registered</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {users.map((user) => (
                <TableRow key={user._id}>
                  <TableCell className="font-medium">{user.name}</TableCell>
                  <TableCell className="text-muted-foreground">{user.email}</TableCell>
                  <TableCell>{roleBadge(user.role)}</TableCell>
                  <TableCell>{statusBadge(user.status)}</TableCell>
                  <TableCell className="text-muted-foreground">
                    {format(new Date(user.createdAt), "MMM d, yyyy")}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        title="Reset Device"
                        onClick={() => setActionDialog({ user, action: "device-reset" })}
                      >
                        <Smartphone className="h-4 w-4" />
                      </Button>
                      {user.status === "active" ? (
                        <Button
                          variant="ghost"
                          size="sm"
                          title="Suspend"
                          onClick={() => setActionDialog({ user, action: "suspended" })}
                        >
                          <XCircle className="h-4 w-4 text-amber-500" />
                        </Button>
                      ) : (
                        <Button
                          variant="ghost"
                          size="sm"
                          title="Activate"
                          onClick={() => setActionDialog({ user, action: "active" })}
                        >
                          <CheckCircle className="h-4 w-4 text-emerald-500" />
                        </Button>
                      )}
                      {user.status !== "banned" && (
                        <Button
                          variant="ghost"
                          size="sm"
                          title="Ban"
                          onClick={() => setActionDialog({ user, action: "banned" })}
                        >
                          <Ban className="h-4 w-4 text-destructive" />
                        </Button>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">
            Page {page} of {totalPages}
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page <= 1}
              onClick={() => setPage((p) => p - 1)}
            >
              Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= totalPages}
              onClick={() => setPage((p) => p + 1)}
            >
              Next
            </Button>
          </div>
        </div>
      )}

      {/* Action Dialog */}
      <Dialog open={!!actionDialog} onOpenChange={() => setActionDialog(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {actionDialog?.action === "device-reset"
                ? "Reset Device Lock"
                : actionDialog?.action === "banned"
                ? "Ban User"
                : actionDialog?.action === "suspended"
                ? "Suspend User"
                : "Activate User"}
            </DialogTitle>
            <DialogDescription>
              {actionDialog?.action === "device-reset"
                ? `This will unbind ${actionDialog.user.name}'s account from their current device, allowing them to log in from a new device.`
                : `Are you sure you want to ${actionDialog?.action === "banned" ? "ban" : actionDialog?.action === "suspended" ? "suspend" : "activate"} ${actionDialog?.user.name}?`}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setActionDialog(null)}>
              Cancel
            </Button>
            <Button
              variant={actionDialog?.action === "banned" ? "destructive" : "default"}
              onClick={handleAction}
              disabled={actionLoading}
            >
              {actionLoading ? <RotateCw className="mr-2 h-4 w-4 animate-spin" /> : null}
              Confirm
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
