import { useState, useEffect, useCallback } from "react"
import { ShieldAlert, CheckCircle, Eye, RotateCw } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
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
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { LoadingState } from "@/components/LoadingState"
import { EmptyState } from "@/components/EmptyState"
import { useAppModal } from "@/components/AppModalProvider"
import { api } from "@/services/api"
import type { SecurityFlag } from "@/types"
import { format } from "date-fns"

export function SecurityPage() {
  const { showError } = useAppModal()
  const [flags, setFlags] = useState<SecurityFlag[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState("")

  // Review dialog
  const [reviewFlag, setReviewFlag] = useState<SecurityFlag | null>(null)
  const [reviewAction, setReviewAction] = useState<SecurityFlag["actionTaken"]>("none")
  const [saving, setSaving] = useState(false)

  const fetchFlags = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.getSecurityFlags({
        flagType: filter || undefined,
      })
      setFlags(res)
    } catch {
      //
    } finally {
      setLoading(false)
    }
  }, [filter])

  useEffect(() => {
    fetchFlags()
  }, [fetchFlags])

  const handleReview = async () => {
    if (!reviewFlag) return
    setSaving(true)
    try {
      await api.reviewSecurityFlag(reviewFlag._id, reviewAction)
      setReviewFlag(null)
      fetchFlags()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Review failed")
    } finally {
      setSaving(false)
    }
  }

  const flagTypeBadge = (type: string) => {
    switch (type) {
      case "screen_recording":
        return <Badge variant="destructive">Screen Recording</Badge>
      case "root_jailbreak":
        return <Badge variant="destructive">Root/Jailbreak</Badge>
      case "vpn_proxy":
        return <Badge className="bg-amber-500/10 text-amber-600 border-amber-200">VPN/Proxy</Badge>
      case "suspicious_activity":
        return <Badge className="bg-orange-500/10 text-orange-600 border-orange-200">Suspicious</Badge>
      default:
        return <Badge variant="outline">{type}</Badge>
    }
  }

  const actionBadge = (action: string) => {
    switch (action) {
      case "none":
        return <Badge variant="secondary">Pending</Badge>
      case "session_terminated":
        return <Badge className="bg-amber-500/10 text-amber-600 border-amber-200">Session Terminated</Badge>
      case "account_suspended":
        return <Badge variant="destructive">Suspended</Badge>
      case "warning_issued":
        return <Badge className="bg-blue-500/10 text-blue-600 border-blue-200">Warning Issued</Badge>
      default:
        return <Badge variant="outline">{action}</Badge>
    }
  }

  if (loading && flags.length === 0) return <LoadingState />

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-4">
        <Select value={filter || "all"} onValueChange={(v) => setFilter(v === "all" ? "" : v)}>
          <SelectTrigger className="w-44">
            <SelectValue placeholder="All types" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Types</SelectItem>
            <SelectItem value="screen_recording">Screen Recording</SelectItem>
            <SelectItem value="root_jailbreak">Root/Jailbreak</SelectItem>
            <SelectItem value="vpn_proxy">VPN/Proxy</SelectItem>
            <SelectItem value="suspicious_activity">Suspicious</SelectItem>
          </SelectContent>
        </Select>
        <span className="text-sm text-muted-foreground">{flags.length} flags</span>
      </div>

      {flags.length === 0 ? (
        <EmptyState title="No security flags" description="No security events have been logged." />
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Type</TableHead>
                <TableHead>Student</TableHead>
                <TableHead>Device</TableHead>
                <TableHead>Action</TableHead>
                <TableHead>Date</TableHead>
                <TableHead className="text-right">Review</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {flags.map((f) => (
                <TableRow key={f._id}>
                  <TableCell>{flagTypeBadge(f.flagType)}</TableCell>
                  <TableCell className="font-medium">
                    {f.studentId ? (typeof f.studentId === "object" ? f.studentId.name : f.studentId) : "—"}
                  </TableCell>
                  <TableCell className="text-muted-foreground text-sm">
                    {f.deviceId || "—"}
                  </TableCell>
                  <TableCell>{actionBadge(f.actionTaken)}</TableCell>
                  <TableCell className="text-muted-foreground">
                    {format(new Date(f.createdAt), "MMM d, yyyy h:mm a")}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => {
                        setReviewFlag(f)
                        setReviewAction(f.actionTaken)
                      }}
                    >
                      {f.actionTaken !== "none" ? (
                        <Eye className="h-4 w-4" />
                      ) : (
                        <ShieldAlert className="h-4 w-4 text-amber-500" />
                      )}
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      {/* Review Dialog */}
      <Dialog open={!!reviewFlag} onOpenChange={() => setReviewFlag(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Review Security Flag</DialogTitle>
          </DialogHeader>
          {reviewFlag && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <span className="text-muted-foreground">Type:</span>{" "}
                  {reviewFlag.flagType.replace(/_/g, " ")}
                </div>
                <div>
                  <span className="text-muted-foreground">Student:</span>{" "}
                  {reviewFlag.studentId
                    ? typeof reviewFlag.studentId === "object"
                      ? reviewFlag.studentId.name
                      : reviewFlag.studentId
                    : "—"}
                </div>
                <div>
                  <span className="text-muted-foreground">Device:</span>{" "}
                  {reviewFlag.deviceId || "—"}
                </div>
                <div>
                  <span className="text-muted-foreground">Date:</span>{" "}
                  {format(new Date(reviewFlag.createdAt), "MMM d, yyyy h:mm a")}
                </div>
                {reviewFlag.metadata && (
                  <div className="col-span-2">
                    <span className="text-muted-foreground">Metadata:</span>
                    <pre className="mt-1 rounded bg-muted p-2 text-xs overflow-auto max-h-24">
                      {JSON.stringify(reviewFlag.metadata, null, 2)}
                    </pre>
                  </div>
                )}
              </div>

              <div className="space-y-2">
                <Label>Action</Label>
                <Select value={reviewAction} onValueChange={(v) => setReviewAction(v as SecurityFlag["actionTaken"])}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="none">None</SelectItem>
                    <SelectItem value="session_terminated">Terminate Session</SelectItem>
                    <SelectItem value="account_suspended">Suspend Account</SelectItem>
                    <SelectItem value="warning_issued">Issue Warning</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setReviewFlag(null)}>Cancel</Button>
            <Button onClick={handleReview} disabled={saving}>
              {saving ? <RotateCw className="mr-2 h-4 w-4 animate-spin" /> : <CheckCircle className="mr-2 h-4 w-4" />}
              Submit Review
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
