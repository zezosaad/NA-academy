import { useState, useEffect } from "react"
import {
  KeyRound,
  Download,
  Ban,
  RotateCw,
  Copy,
  Check,
  ChevronDown,
  ChevronUp,
  Plus,
  Search,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
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
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { LoadingState } from "@/components/LoadingState"
import { useAppModal } from "@/components/AppModalProvider"
import { api } from "@/services/api"
import type {
  Subject,
  SubjectBundle,
  Exam,
  SubjectCode,
  ExamCode,
} from "@/types"
import { format } from "date-fns"

type EntityKind = "subject" | "bundle" | "exam"

type EntityStat = {
  _id: string
  title?: string
  name?: string
  category?: string
  isActive?: boolean
  total: number
  available: number
  used: number
  expired: number
}

type EntityCodes = {
  data: (SubjectCode | ExamCode)[]
  loading: boolean
  error?: string
}

export function CodesPage() {
  const { showError } = useAppModal()
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [bundles, setBundles] = useState<SubjectBundle[]>([])
  const [exams, setExams] = useState<Exam[]>([])
  const [entityStats, setEntityStats] = useState<{
    subjects: EntityStat[]
    bundles: EntityStat[]
    exams: EntityStat[]
  }>({ subjects: [], bundles: [], exams: [] })
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState<EntityKind>("subject")
  const [search, setSearch] = useState("")

  // Per-entity expanded codes
  const [expanded, setExpanded] = useState<Record<string, EntityCodes>>({})
  const [copiedKey, setCopiedKey] = useState<string | null>(null)

  // Generate dialog
  const [genDialog, setGenDialog] = useState(false)
  const [genType, setGenType] = useState<"subject" | "exam">("subject")
  const [genForm, setGenForm] = useState({
    targetId: "",
    targetType: "subject" as "subject" | "bundle",
    quantity: 10,
    usageType: "single" as "single" | "multi",
    maxUses: 1,
    timeLimitMinutes: 0,
  })
  const [generating, setGenerating] = useState(false)

  // Revoke
  const [revokeTarget, setRevokeTarget] = useState<{
    type: "code" | "batch" | "all-for-entity"
    id: string
    label: string
    entityKey?: string
  } | null>(null)

  const reloadStats = async () => {
    try {
      const stats = await api.getCodesByEntity()
      setEntityStats(stats)
    } catch (err) {
      console.error("Failed to load codes by entity", err)
    }
  }

  useEffect(() => {
    ;(async () => {
      setLoading(true)
      try {
        const [subRes, bunRes, examRes] = await Promise.allSettled([
          api.getSubjects({ limit: 100 }),
          api.getBundles(),
          api.getExams({ limit: 100 }),
        ])
        if (subRes.status === "fulfilled") setSubjects(subRes.value.data)
        if (bunRes.status === "fulfilled") setBundles(bunRes.value)
        if (examRes.status === "fulfilled") setExams(examRes.value.data)
        await reloadStats()
      } catch {
        //
      } finally {
        setLoading(false)
      }
    })()
  }, [])

  const expandKey = (kind: EntityKind, id: string) => `${kind}:${id}`

  const toggleExpand = async (kind: EntityKind, id: string) => {
    const key = expandKey(kind, id)
    if (expanded[key]) {
      setExpanded((prev) => {
        const next = { ...prev }
        delete next[key]
        return next
      })
      return
    }
    setExpanded((prev) => ({ ...prev, [key]: { data: [], loading: true } }))
    try {
      const fetcher =
        kind === "subject"
          ? api.getCodesForSubject(id)
          : kind === "bundle"
          ? api.getCodesForBundle(id)
          : api.getCodesForExam(id)
      const res = await fetcher
      setExpanded((prev) => ({
        ...prev,
        [key]: { data: res.data ?? [], loading: false },
      }))
    } catch (err) {
      setExpanded((prev) => ({
        ...prev,
        [key]: {
          data: [],
          loading: false,
          error: err instanceof Error ? err.message : "Failed to load codes",
        },
      }))
    }
  }

  const refreshExpanded = async (kind: EntityKind, id: string) => {
    const key = expandKey(kind, id)
    if (!expanded[key]) return
    setExpanded((prev) => ({ ...prev, [key]: { data: [], loading: true } }))
    try {
      const fetcher =
        kind === "subject"
          ? api.getCodesForSubject(id)
          : kind === "bundle"
          ? api.getCodesForBundle(id)
          : api.getCodesForExam(id)
      const res = await fetcher
      setExpanded((prev) => ({
        ...prev,
        [key]: { data: res.data ?? [], loading: false },
      }))
    } catch (err) {
      setExpanded((prev) => ({
        ...prev,
        [key]: {
          data: [],
          loading: false,
          error: err instanceof Error ? err.message : "Failed to load codes",
        },
      }))
    }
  }

  const openGenerateForEntity = (kind: EntityKind, id: string) => {
    if (kind === "exam") {
      setGenType("exam")
      setGenForm({ ...genForm, targetId: id, targetType: "subject" })
    } else {
      setGenType("subject")
      setGenForm({
        ...genForm,
        targetId: id,
        targetType: kind === "bundle" ? "bundle" : "subject",
      })
    }
    setGenDialog(true)
  }

  const handleGenerate = async () => {
    setGenerating(true)
    try {
      let result: { batchId: string }
      if (genType === "subject") {
        const payload: {
          subjectId?: string
          bundleId?: string
          quantity: number
        } = { quantity: genForm.quantity }
        if (genForm.targetType === "bundle") payload.bundleId = genForm.targetId
        else payload.subjectId = genForm.targetId
        result = await api.generateSubjectCodes(payload)
      } else {
        result = await api.generateExamCodes({
          examId: genForm.targetId,
          quantity: genForm.quantity,
          usageType: genForm.usageType,
          maxUses:
            genForm.usageType === "multi" ? genForm.maxUses : undefined,
          timeLimitMinutes: genForm.timeLimitMinutes || undefined,
        })
      }

      setGenDialog(false)
      await reloadStats()

      // If a row for this entity is expanded, refresh it. Otherwise expand it.
      const kind: EntityKind =
        genType === "exam"
          ? "exam"
          : genForm.targetType === "bundle"
          ? "bundle"
          : "subject"
      const key = expandKey(kind, genForm.targetId)
      if (expanded[key]) {
        await refreshExpanded(kind, genForm.targetId)
      } else {
        await toggleExpand(kind, genForm.targetId)
      }

      // Show batch info in a small toast-like way
      console.log("Generated batch", result.batchId)
    } catch (err) {
      showError(err instanceof Error ? err.message : "Generation failed")
    } finally {
      setGenerating(false)
    }
  }

  const handleExport = async (batchIdToExport: string) => {
    try {
      const blob = await api.exportBatch(batchIdToExport, "csv")
      const url = URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `batch-${batchIdToExport}.csv`
      a.click()
      URL.revokeObjectURL(url)
    } catch (err) {
      showError(err instanceof Error ? err.message : "Export failed")
    }
  }

  const handleRevoke = async () => {
    if (!revokeTarget) return
    try {
      if (revokeTarget.type === "batch") {
        await api.revokeBatch(revokeTarget.id)
      } else if (revokeTarget.type === "code") {
        await api.revokeCode(revokeTarget.id)
      }
      const target = revokeTarget
      setRevokeTarget(null)
      await reloadStats()
      // Refresh any open expanded rows that contain this code/batch
      if (target.entityKey) {
        const [kind, id] = target.entityKey.split(":") as [EntityKind, string]
        await refreshExpanded(kind, id)
      } else {
        // Refresh all open rows since we don't know which entity owns this
        for (const key of Object.keys(expanded)) {
          const [kind, id] = key.split(":") as [EntityKind, string]
          await refreshExpanded(kind, id)
        }
      }
    } catch (err) {
      showError(err instanceof Error ? err.message : "Revoke failed")
    }
  }

  const copyCode = (code: string, key: string) => {
    navigator.clipboard.writeText(code)
    setCopiedKey(key)
    setTimeout(() => setCopiedKey(null), 1500)
  }

  const copyAllAvailable = (codes: (SubjectCode | ExamCode)[]) => {
    const text = codes
      .filter((c) => c.status === "available")
      .map((c) => c.code)
      .join("\n")
    if (!text) {
      showError("No available codes to copy")
      return
    }
    navigator.clipboard.writeText(text)
  }

  const statusBadge = (status: string) => {
    switch (status) {
      case "available":
        return (
          <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">
            Available
          </Badge>
        )
      case "used":
        return <Badge variant="secondary">Used</Badge>
      case "expired":
        return <Badge variant="destructive">Expired</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  if (loading) return <LoadingState />

  const visibleStats =
    tab === "subject"
      ? entityStats.subjects
      : tab === "bundle"
      ? entityStats.bundles
      : entityStats.exams

  const filteredStats = search.trim()
    ? visibleStats.filter((s) => {
        const label = (s.title || s.name || "").toLowerCase()
        return label.includes(search.toLowerCase())
      })
    : visibleStats

  const entityLabel = (s: EntityStat) =>
    s.title || s.name || `(deleted) ${s._id.slice(-6)}`

  return (
    <div className="space-y-6">
      {/* Action bar */}
      <div className="flex flex-wrap items-center gap-3">
        <Button
          size="sm"
          onClick={() => {
            setGenType("subject")
            setGenForm({ ...genForm, targetId: "", targetType: "subject" })
            setGenDialog(true)
          }}
        >
          <KeyRound className="mr-2 h-4 w-4" />
          Generate Subject Codes
        </Button>
        <Button
          size="sm"
          variant="outline"
          onClick={() => {
            setGenType("exam")
            setGenForm({ ...genForm, targetId: "" })
            setGenDialog(true)
          }}
        >
          <KeyRound className="mr-2 h-4 w-4" />
          Generate Exam Codes
        </Button>
        <div className="flex-1" />
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9 w-64"
          />
        </div>
        <Button size="sm" variant="ghost" onClick={reloadStats}>
          <RotateCw className="mr-2 h-4 w-4" /> Refresh
        </Button>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 border-b">
        {(
          [
            { key: "subject", label: "Subjects", count: entityStats.subjects.length },
            { key: "bundle", label: "Bundles", count: entityStats.bundles.length },
            { key: "exam", label: "Exams", count: entityStats.exams.length },
          ] as { key: EntityKind; label: string; count: number }[]
        ).map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`px-4 py-2 text-sm font-medium transition-colors border-b-2 -mb-px ${
              tab === t.key
                ? "border-foreground text-foreground"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            {t.label}
            <Badge variant="outline" className="ml-2">
              {t.count}
            </Badge>
          </button>
        ))}
      </div>

      {/* Entity list */}
      {filteredStats.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center text-muted-foreground">
            No codes generated yet for any{" "}
            {tab === "subject" ? "subject" : tab === "bundle" ? "bundle" : "exam"}.
            Use the button above to generate.
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {filteredStats.map((s) => {
            const key = expandKey(tab, s._id)
            const exp = expanded[key]
            const isOpen = !!exp
            return (
              <Card key={s._id}>
                <CardHeader
                  className="flex flex-row items-center justify-between cursor-pointer"
                  onClick={() => toggleExpand(tab, s._id)}
                >
                  <div className="flex flex-col gap-1">
                    <CardTitle className="text-base flex items-center gap-2">
                      {entityLabel(s)}
                      {s.isActive === false && (
                        <Badge variant="outline" className="text-amber-600 border-amber-200">
                          Inactive
                        </Badge>
                      )}
                    </CardTitle>
                    <div className="flex items-center gap-2 text-xs text-muted-foreground">
                      <span>Total: <strong>{s.total}</strong></span>
                      <span className="text-emerald-600">
                        Available: <strong>{s.available}</strong>
                      </span>
                      <span>Used: <strong>{s.used}</strong></span>
                      {s.expired > 0 && (
                        <span className="text-destructive">
                          Expired: <strong>{s.expired}</strong>
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="flex gap-2 items-center">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={(e) => {
                        e.stopPropagation()
                        openGenerateForEntity(tab, s._id)
                      }}
                    >
                      <Plus className="mr-2 h-4 w-4" /> Generate more
                    </Button>
                    {isOpen ? (
                      <ChevronUp className="h-4 w-4" />
                    ) : (
                      <ChevronDown className="h-4 w-4" />
                    )}
                  </div>
                </CardHeader>
                {isOpen && (
                  <CardContent className="space-y-3">
                    {exp?.loading ? (
                      <div className="py-6 text-center text-sm text-muted-foreground">
                        <RotateCw className="mx-auto mb-2 h-4 w-4 animate-spin" />
                        Loading codes…
                      </div>
                    ) : exp?.error ? (
                      <div className="py-6 text-center text-sm text-destructive">
                        {exp.error}
                      </div>
                    ) : (
                      <>
                        <div className="flex items-center gap-2">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => copyAllAvailable(exp!.data)}
                          >
                            <Copy className="mr-2 h-4 w-4" /> Copy all available
                          </Button>
                        </div>
                        <div className="rounded-md border max-h-96 overflow-auto">
                          <Table>
                            <TableHeader>
                              <TableRow>
                                <TableHead>Code</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead>Batch</TableHead>
                                <TableHead>Activated By</TableHead>
                                <TableHead>Activated At</TableHead>
                                <TableHead className="text-right">Actions</TableHead>
                              </TableRow>
                            </TableHeader>
                            <TableBody>
                              {exp!.data.map((c, i) => (
                                <TableRow key={c._id}>
                                  <TableCell>
                                    <button
                                      onClick={() =>
                                        copyCode(c.code, `${key}:${c._id}`)
                                      }
                                      className="font-mono text-sm flex items-center gap-2 hover:text-foreground transition-colors"
                                      title="Click to copy"
                                    >
                                      {copiedKey === `${key}:${c._id}` ? (
                                        <Check className="h-3 w-3 text-emerald-500" />
                                      ) : (
                                        <Copy className="h-3 w-3 text-muted-foreground" />
                                      )}
                                      {c.code}
                                    </button>
                                  </TableCell>
                                  <TableCell>{statusBadge(c.status)}</TableCell>
                                  <TableCell className="text-xs text-muted-foreground font-mono">
                                    {c.batchId.replace("batch_", "")}
                                  </TableCell>
                                  <TableCell className="text-muted-foreground">
                                    {c.activatedBy ? c.activatedBy.name : "—"}
                                  </TableCell>
                                  <TableCell className="text-muted-foreground">
                                    {c.activatedAt
                                      ? format(
                                          new Date(c.activatedAt),
                                          "MMM d, yyyy h:mm a"
                                        )
                                      : "—"}
                                  </TableCell>
                                  <TableCell className="text-right">
                                    <div className="flex gap-1 justify-end">
                                      <Button
                                        variant="ghost"
                                        size="sm"
                                        onClick={() => handleExport(c.batchId)}
                                        title="Export batch"
                                      >
                                        <Download className="h-4 w-4" />
                                      </Button>
                                      {c.status === "available" && (
                                        <Button
                                          variant="ghost"
                                          size="sm"
                                          onClick={() =>
                                            setRevokeTarget({
                                              type: "code",
                                              id: c._id,
                                              label: c.code,
                                              entityKey: key,
                                            })
                                          }
                                          title="Revoke code"
                                        >
                                          <Ban className="h-4 w-4 text-destructive" />
                                        </Button>
                                      )}
                                    </div>
                                  </TableCell>
                                </TableRow>
                              ))}
                              {exp!.data.length === 0 && (
                                <TableRow>
                                  <TableCell
                                    colSpan={6}
                                    className="text-center text-muted-foreground py-6"
                                  >
                                    No codes
                                  </TableCell>
                                </TableRow>
                              )}
                            </TableBody>
                          </Table>
                        </div>
                      </>
                    )}
                  </CardContent>
                )}
              </Card>
            )
          })}
        </div>
      )}

      {/* Generate Dialog */}
      <Dialog open={genDialog} onOpenChange={setGenDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              Generate {genType === "subject" ? "Subject" : "Exam"} Codes
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            {genType === "subject" ? (
              <>
                <div className="space-y-2">
                  <Label>Type</Label>
                  <Select
                    value={genForm.targetType}
                    onValueChange={(v) =>
                      setGenForm((f) => ({
                        ...f,
                        targetType: v as "subject" | "bundle",
                        targetId: "",
                      }))
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="subject">Subject</SelectItem>
                      <SelectItem value="bundle">Bundle</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>
                    {genForm.targetType === "subject" ? "Subject" : "Bundle"}
                  </Label>
                  <Select
                    value={genForm.targetId}
                    onValueChange={(v) =>
                      setGenForm((f) => ({ ...f, targetId: v }))
                    }
                  >
                    <SelectTrigger>
                      <SelectValue
                        placeholder={`Select ${genForm.targetType}`}
                      />
                    </SelectTrigger>
                    <SelectContent>
                      {genForm.targetType === "subject"
                        ? subjects.map((s) => (
                            <SelectItem key={s._id} value={s._id}>
                              {s.title}
                            </SelectItem>
                          ))
                        : bundles.map((b) => (
                            <SelectItem key={b._id} value={b._id}>
                              {b.name}
                            </SelectItem>
                          ))}
                    </SelectContent>
                  </Select>
                </div>
              </>
            ) : (
              <>
                <div className="space-y-2">
                  <Label>Exam</Label>
                  <Select
                    value={genForm.targetId}
                    onValueChange={(v) =>
                      setGenForm((f) => ({ ...f, targetId: v }))
                    }
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select exam" />
                    </SelectTrigger>
                    <SelectContent>
                      {exams.map((e) => (
                        <SelectItem key={e._id} value={e._id}>
                          {e.title}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Usage Type</Label>
                  <Select
                    value={genForm.usageType}
                    onValueChange={(v) =>
                      setGenForm((f) => ({
                        ...f,
                        usageType: v as "single" | "multi",
                      }))
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="single">Single Use</SelectItem>
                      <SelectItem value="multi">Multi Use</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                {genForm.usageType === "multi" && (
                  <div className="space-y-2">
                    <Label>Max Uses</Label>
                    <Input
                      type="number"
                      min={2}
                      value={genForm.maxUses}
                      onChange={(e) =>
                        setGenForm((f) => ({
                          ...f,
                          maxUses: +e.target.value,
                        }))
                      }
                    />
                  </div>
                )}
                <div className="space-y-2">
                  <Label>Time Limit (minutes, 0 = no limit)</Label>
                  <Input
                    type="number"
                    min={0}
                    value={genForm.timeLimitMinutes}
                    onChange={(e) =>
                      setGenForm((f) => ({
                        ...f,
                        timeLimitMinutes: +e.target.value,
                      }))
                    }
                  />
                </div>
              </>
            )}

            <div className="space-y-2">
              <Label>Quantity</Label>
              <Input
                type="number"
                min={1}
                max={10000}
                value={genForm.quantity}
                onChange={(e) =>
                  setGenForm((f) => ({ ...f, quantity: +e.target.value }))
                }
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setGenDialog(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleGenerate}
              disabled={
                generating || !genForm.targetId || genForm.quantity < 1
              }
            >
              {generating ? (
                <RotateCw className="mr-2 h-4 w-4 animate-spin" />
              ) : null}
              Generate {genForm.quantity} Codes
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Revoke Confirmation */}
      <AlertDialog
        open={!!revokeTarget}
        onOpenChange={() => setRevokeTarget(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Revoke {revokeTarget?.label}?</AlertDialogTitle>
            <AlertDialogDescription>
              {revokeTarget?.type === "batch"
                ? "This will revoke ALL available codes in this batch."
                : "This code will become expired and unusable."}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleRevoke}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Revoke
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
