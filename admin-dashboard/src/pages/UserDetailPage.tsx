import { useCallback, useEffect, useState } from "react"
import { useNavigate, useParams } from "react-router-dom"
import {
  ArrowLeft,
  Smartphone,
  Ban,
  CheckCircle,
  XCircle,
  RotateCw,
  ShieldAlert,
  BookOpen,
  GraduationCap,
  Clock,
  AlertTriangle,
  Mail,
  Calendar,
  Activity,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
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
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { LoadingState } from "@/components/LoadingState"
import { EmptyState } from "@/components/EmptyState"
import { useAppModal } from "@/components/AppModalProvider"
import { api } from "@/services/api"
import {
  EDUCATION_LEVEL_OPTIONS,
  type EducationLevel,
  type UserDetail,
  type UserStatus,
} from "@/types"
import { format } from "date-fns"

const levelLabel = (level?: EducationLevel) =>
  EDUCATION_LEVEL_OPTIONS.find((o) => o.value === level)?.label ?? "—"

const formatSeconds = (s: number) => {
  if (!s) return "0m"
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  if (h > 0) return `${h}h ${m}m`
  return `${m}m`
}

const flagLabel = (type: string) => {
  switch (type) {
    case "screen_recording":
      return "Screen Recording"
    case "root_jailbreak":
      return "Root / Jailbreak"
    case "vpn_proxy":
      return "VPN / Proxy"
    case "suspicious_activity":
      return "Suspicious Activity"
    default:
      return type
  }
}

export function UserDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { showError } = useAppModal()

  const [data, setData] = useState<UserDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [actionDialog, setActionDialog] = useState<
    "active" | "suspended" | "banned" | "device-reset" | null
  >(null)
  const [actionLoading, setActionLoading] = useState(false)
  const [savingLevel, setSavingLevel] = useState(false)

  const fetchData = useCallback(async () => {
    if (!id) return
    setLoading(true)
    try {
      const res = await api.getUserDetail(id)
      setData(res)
    } catch (err) {
      showError(err instanceof Error ? err.message : "Failed to load user")
    } finally {
      setLoading(false)
    }
  }, [id, showError])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const handleStatusAction = async () => {
    if (!actionDialog || !data) return
    setActionLoading(true)
    try {
      if (actionDialog === "device-reset") {
        await api.resetUserDevice(data.profile.id)
      } else {
        await api.updateUserStatus(data.profile.id, actionDialog as UserStatus)
      }
      setActionDialog(null)
      await fetchData()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Action failed")
    } finally {
      setActionLoading(false)
    }
  }

  const handleLevelChange = async (level: EducationLevel) => {
    if (!data || level === data.profile.level) return
    setSavingLevel(true)
    try {
      await api.updateUserLevel(data.profile.id, level)
      await fetchData()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Failed to update level")
    } finally {
      setSavingLevel(false)
    }
  }

  if (loading) return <LoadingState />
  if (!data) return <EmptyState title="User not found" description="Could not load this user." />

  const { profile, device, sessions, activations, activity, securityFlags } = data

  const statusBadge = (status: UserStatus) => {
    switch (status) {
      case "active":
        return (
          <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">
            Active
          </Badge>
        )
      case "suspended":
        return <Badge variant="secondary">Suspended</Badge>
      case "banned":
        return <Badge variant="destructive">Banned</Badge>
    }
  }

  const roleBadge = (role: string) => {
    switch (role) {
      case "admin":
        return (
          <Badge className="bg-purple-500/10 text-purple-600 border-purple-200">
            Admin
          </Badge>
        )
      case "teacher":
        return (
          <Badge className="bg-blue-500/10 text-blue-600 border-blue-200">Teacher</Badge>
        )
      default:
        return <Badge variant="outline">Student</Badge>
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="sm" onClick={() => navigate("/users")}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Users
        </Button>
      </div>

      {/* Profile Card */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div className="flex items-center gap-4">
              <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 text-2xl font-bold uppercase text-primary">
                {profile.name.charAt(0)}
              </div>
              <div>
                <h1 className="text-2xl font-bold">{profile.name}</h1>
                <div className="flex items-center gap-2 text-muted-foreground">
                  <Mail className="h-4 w-4" />
                  <span>{profile.email}</span>
                </div>
                <div className="mt-2 flex flex-wrap items-center gap-2">
                  {roleBadge(profile.role)}
                  {statusBadge(profile.status)}
                  {profile.level ? (
                    <Badge variant="outline">{levelLabel(profile.level)}</Badge>
                  ) : null}
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="flex flex-wrap items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setActionDialog("device-reset")}
              >
                <Smartphone className="mr-2 h-4 w-4" />
                Reset Device
              </Button>
              {profile.status === "active" ? (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setActionDialog("suspended")}
                >
                  <XCircle className="mr-2 h-4 w-4 text-amber-500" />
                  Suspend
                </Button>
              ) : (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setActionDialog("active")}
                >
                  <CheckCircle className="mr-2 h-4 w-4 text-emerald-500" />
                  Activate
                </Button>
              )}
              {profile.status !== "banned" && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setActionDialog("banned")}
                >
                  <Ban className="mr-2 h-4 w-4 text-destructive" />
                  Ban
                </Button>
              )}
            </div>
          </div>

          {/* Meta grid */}
          <div className="mt-6 grid gap-4 border-t pt-6 md:grid-cols-3">
            <MetaItem
              icon={<Calendar className="h-4 w-4" />}
              label="Registered"
              value={format(new Date(profile.createdAt), "MMM d, yyyy")}
            />
            <MetaItem
              icon={<Activity className="h-4 w-4" />}
              label="Active sessions"
              value={String(sessions.activeCount)}
            />
            <MetaItem
              icon={<Clock className="h-4 w-4" />}
              label="Last activity"
              value={
                sessions.lastActivityAt
                  ? format(new Date(sessions.lastActivityAt), "MMM d, yyyy HH:mm")
                  : "Never"
              }
            />
          </div>

          {/* Level changer (admin) */}
          {profile.role === "student" && (
            <div className="mt-6 flex flex-wrap items-center gap-3 border-t pt-6">
              <GraduationCap className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm font-medium">Education Level:</span>
              <div className="min-w-[240px]">
                <Select
                  value={profile.level ?? undefined}
                  onValueChange={(v) => handleLevelChange(v as EducationLevel)}
                  disabled={savingLevel}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select level" />
                  </SelectTrigger>
                  <SelectContent>
                    {EDUCATION_LEVEL_OPTIONS.map((opt) => (
                      <SelectItem key={opt.value} value={opt.value}>
                        {opt.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              {savingLevel && (
                <RotateCw className="h-4 w-4 animate-spin text-muted-foreground" />
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Device */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <Smartphone className="h-4 w-4" /> Device
          </CardTitle>
        </CardHeader>
        <CardContent>
          {device ? (
            <div className="grid gap-4 md:grid-cols-3">
              <MetaItem
                label="Hardware ID"
                value={
                  <span className="break-all font-mono text-xs">{device.hardwareId}</span>
                }
              />
              <MetaItem
                label="Status"
                value={
                  device.isActive ? (
                    <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">
                      Active
                    </Badge>
                  ) : (
                    <Badge variant="secondary">Reset</Badge>
                  )
                }
              />
              <MetaItem
                label="Registered"
                value={format(new Date(device.registeredAt), "MMM d, yyyy")}
              />
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">No device registered.</p>
          )}
        </CardContent>
      </Card>

      {/* Activations */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <BookOpen className="h-4 w-4" /> Subject Activations
            <Badge variant="secondary" className="ml-auto">
              {activations.subjects.length}
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {activations.subjects.length === 0 ? (
            <p className="text-sm text-muted-foreground">No subjects activated yet.</p>
          ) : (
            <div className="overflow-x-auto rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Subject / Bundle</TableHead>
                    <TableHead>Code</TableHead>
                    <TableHead>Activated</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {activations.subjects.map((a) => (
                    <TableRow key={a.codeId}>
                      <TableCell>
                        {a.subject ? (
                          <div className="flex flex-col">
                            <span className="font-medium">{a.subject.title}</span>
                            <span className="text-xs text-muted-foreground">
                              {a.subject.category}
                              {a.subject.level ? ` · ${levelLabel(a.subject.level)}` : ""}
                            </span>
                          </div>
                        ) : a.bundle ? (
                          <div>
                            <Badge variant="outline" className="mr-2">
                              Bundle
                            </Badge>
                            {a.bundle.name}
                          </div>
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </TableCell>
                      <TableCell className="font-mono text-xs">{a.code}</TableCell>
                      <TableCell className="text-muted-foreground">
                        {a.activatedAt
                          ? format(new Date(a.activatedAt), "MMM d, yyyy")
                          : "—"}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Exam Activations */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <GraduationCap className="h-4 w-4" /> Exam Activations
            <Badge variant="secondary" className="ml-auto">
              {activations.exams.length}
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {activations.exams.length === 0 ? (
            <p className="text-sm text-muted-foreground">No exams activated.</p>
          ) : (
            <div className="overflow-x-auto rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Exam</TableHead>
                    <TableHead>Code</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>First used</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {activations.exams.map((a) => (
                    <TableRow key={a.codeId}>
                      <TableCell className="font-medium">
                        {a.exam?.title ?? "—"}
                      </TableCell>
                      <TableCell className="font-mono text-xs">{a.code}</TableCell>
                      <TableCell>
                        <Badge variant="outline">
                          {a.usageType === "multi"
                            ? `Multi (${a.remainingUses ?? 0}/${a.maxUses ?? 0})`
                            : "Single"}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Badge variant={a.status === "expired" ? "destructive" : "secondary"}>
                          {a.status}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {a.firstActivatedAt
                          ? format(new Date(a.firstActivatedAt), "MMM d, yyyy")
                          : "—"}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Watch Activity */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <Clock className="h-4 w-4" /> Watch Activity
            <span className="ml-auto text-sm font-normal text-muted-foreground">
              Total: {formatSeconds(activity.totalWatchSeconds)}
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {activity.watchTimeBySubject.length === 0 ? (
            <p className="text-sm text-muted-foreground">No watch activity recorded.</p>
          ) : (
            <div className="overflow-x-auto rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Subject</TableHead>
                    <TableHead>Watch time</TableHead>
                    <TableHead>Last watched</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {activity.watchTimeBySubject.map((w) => (
                    <TableRow key={w.subjectId}>
                      <TableCell className="font-medium">
                        {w.subjectTitle ?? "(deleted)"}
                      </TableCell>
                      <TableCell>{formatSeconds(w.totalSeconds)}</TableCell>
                      <TableCell className="text-muted-foreground">
                        {format(new Date(w.lastWatched), "MMM d, yyyy")}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Exam Attempts */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <Activity className="h-4 w-4" /> Recent Exam Attempts
          </CardTitle>
        </CardHeader>
        <CardContent>
          {activity.examAttempts.length === 0 ? (
            <p className="text-sm text-muted-foreground">No exam attempts.</p>
          ) : (
            <div className="overflow-x-auto rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Exam</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Score</TableHead>
                    <TableHead>Started</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {activity.examAttempts.map((a) => (
                    <TableRow key={a.sessionId}>
                      <TableCell className="font-medium">
                        {a.examTitle ?? "—"}
                        {a.isFreeAttempt && (
                          <Badge variant="outline" className="ml-2 text-xs">
                            Free
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        <Badge
                          variant={
                            a.status === "completed"
                              ? "default"
                              : a.status === "timed_out" || a.status === "abandoned"
                                ? "destructive"
                                : "secondary"
                          }
                        >
                          {a.status.replace("_", " ")}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {a.scorePercentage !== undefined
                          ? `${a.scorePercentage.toFixed(0)}% (${a.correctAnswers}/${a.totalQuestions})`
                          : "—"}
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {format(new Date(a.startedAt), "MMM d, HH:mm")}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Security Flags */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <ShieldAlert className="h-4 w-4" /> Security Flags
            <Badge
              variant={securityFlags.length > 0 ? "destructive" : "secondary"}
              className="ml-auto"
            >
              {securityFlags.length}
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {securityFlags.length === 0 ? (
            <p className="text-sm text-muted-foreground">No security flags.</p>
          ) : (
            <div className="overflow-x-auto rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Type</TableHead>
                    <TableHead>Action</TableHead>
                    <TableHead>When</TableHead>
                    <TableHead>Reviewed</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {securityFlags.map((f) => (
                    <TableRow key={f.id}>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <AlertTriangle className="h-4 w-4 text-amber-500" />
                          {flagLabel(f.flagType)}
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{f.actionTaken.replace("_", " ")}</Badge>
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {format(new Date(f.createdAt), "MMM d, HH:mm")}
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {f.reviewedAt ? format(new Date(f.reviewedAt), "MMM d") : "Pending"}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Action Dialog */}
      <Dialog open={!!actionDialog} onOpenChange={() => setActionDialog(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {actionDialog === "device-reset"
                ? "Reset Device Lock"
                : actionDialog === "banned"
                  ? "Ban User"
                  : actionDialog === "suspended"
                    ? "Suspend User"
                    : "Activate User"}
            </DialogTitle>
            <DialogDescription>
              {actionDialog === "device-reset"
                ? `Unbind ${profile.name}'s account from their current device, allowing login from a new device.`
                : `Are you sure you want to ${actionDialog} ${profile.name}?`}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setActionDialog(null)}>
              Cancel
            </Button>
            <Button
              variant={actionDialog === "banned" ? "destructive" : "default"}
              onClick={handleStatusAction}
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

function MetaItem({
  icon,
  label,
  value,
}: {
  icon?: React.ReactNode
  label: string
  value: React.ReactNode
}) {
  return (
    <div className="space-y-1">
      <div className="flex items-center gap-2 text-xs uppercase tracking-wide text-muted-foreground">
        {icon}
        {label}
      </div>
      <div className="text-sm">{value}</div>
    </div>
  )
}
