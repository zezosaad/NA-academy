import { useState, useEffect } from "react"
import {
  KeyRound,
  Download,
  Ban,
  RotateCw,
  Copy,
  Check,
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
import { api } from "@/services/api"
import type { Subject, SubjectBundle, Exam, SubjectCode, ExamCode } from "@/types"
import { format } from "date-fns"

export function CodesPage() {
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [bundles, setBundles] = useState<SubjectBundle[]>([])
  const [exams, setExams] = useState<Exam[]>([])
  const [loading, setLoading] = useState(true)

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

  // Generated result
  const [generatedCodes, setGeneratedCodes] = useState<(SubjectCode | ExamCode)[]>([])
  const [generatedBatchId, setGeneratedBatchId] = useState<string | null>(null)
  const [copiedIdx, setCopiedIdx] = useState<number | null>(null)

  // Batch lookup
  const [batchInput, setBatchInput] = useState("")
  const [batchCodes, setBatchCodes] = useState<(SubjectCode | ExamCode)[]>([])
  const [batchLoading, setBatchLoading] = useState(false)
  const [batchId, setBatchId] = useState<string | null>(null)

  // Revoke
  const [revokeTarget, setRevokeTarget] = useState<{
    type: "code" | "batch"
    id: string
    label: string
  } | null>(null)

  useEffect(() => {
    (async () => {
      setLoading(true)
      try {
        const [subRes, bunRes, examRes] = await Promise.all([
          api.getSubjects({ limit: 100 }),
          api.getBundles(),
          api.getExams({ limit: 100 }),
        ])
        setSubjects(subRes.data)
        setBundles(bunRes)
        setExams(examRes.data)
      } catch {
        //
      } finally {
        setLoading(false)
      }
    })()
  }, [])

  const handleGenerate = async () => {
    setGenerating(true)
    try {
      let result: { batchId: string; codes: (SubjectCode | ExamCode)[] }
      if (genType === "subject") {
        const payload: { subjectId?: string; bundleId?: string; quantity: number } = {
          quantity: genForm.quantity,
        }
        if (genForm.targetType === "bundle") payload.bundleId = genForm.targetId
        else payload.subjectId = genForm.targetId
        result = await api.generateSubjectCodes(payload)
      } else {
        result = await api.generateExamCodes({
          examId: genForm.targetId,
          quantity: genForm.quantity,
          usageType: genForm.usageType,
          maxUses: genForm.usageType === "multi" ? genForm.maxUses : undefined,
          timeLimitMinutes: genForm.timeLimitMinutes || undefined,
        })
      }
      setGeneratedCodes(result.codes)
      setGeneratedBatchId(result.batchId)
      setGenDialog(false)
    } catch (err) {
      alert(err instanceof Error ? err.message : "Generation failed")
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
      alert(err instanceof Error ? err.message : "Export failed")
    }
  }

  const handleBatchLookup = async () => {
    if (!batchInput.trim()) return
    setBatchLoading(true)
    try {
      const codes = await api.getBatchCodes(batchInput.trim())
      setBatchCodes(codes)
      setBatchId(batchInput.trim())
    } catch (err) {
      alert(err instanceof Error ? err.message : "Lookup failed")
    } finally {
      setBatchLoading(false)
    }
  }

  const handleRevoke = async () => {
    if (!revokeTarget) return
    try {
      if (revokeTarget.type === "batch") {
        await api.revokeBatch(revokeTarget.id)
      } else {
        await api.revokeCode(revokeTarget.id)
      }
      setRevokeTarget(null)
      // Refresh batch if viewing one
      if (batchId) {
        const codes = await api.getBatchCodes(batchId)
        setBatchCodes(codes)
      }
    } catch (err) {
      alert(err instanceof Error ? err.message : "Revoke failed")
    }
  }

  const copyCode = (code: string, idx: number) => {
    navigator.clipboard.writeText(code)
    setCopiedIdx(idx)
    setTimeout(() => setCopiedIdx(null), 1500)
  }

  const statusBadge = (status: string) => {
    switch (status) {
      case "available":
        return <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">Available</Badge>
      case "used":
        return <Badge variant="secondary">Used</Badge>
      case "expired":
        return <Badge variant="destructive">Expired</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  if (loading) return <LoadingState />

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
      </div>

      {/* Generated codes result */}
      {generatedCodes.length > 0 && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="text-base">
              Generated {generatedCodes.length} codes — Batch: {generatedBatchId}
            </CardTitle>
            <div className="flex gap-2">
              <Button size="sm" variant="outline" onClick={() => handleExport(generatedBatchId!)}>
                <Download className="mr-2 h-4 w-4" /> Export CSV
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => {
                  const allCodes = generatedCodes.map((c) => c.code).join("\n")
                  navigator.clipboard.writeText(allCodes)
                }}
              >
                <Copy className="mr-2 h-4 w-4" /> Copy All
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 max-h-60 overflow-auto">
              {generatedCodes.map((c, i) => (
                <button
                  key={c._id}
                  className="flex items-center gap-2 rounded-md border px-3 py-2 text-sm font-mono hover:bg-muted transition-colors"
                  onClick={() => copyCode(c.code, i)}
                >
                  {copiedIdx === i ? <Check className="h-3 w-3 text-emerald-500" /> : <Copy className="h-3 w-3 text-muted-foreground" />}
                  {c.code}
                </button>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Batch Lookup */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Batch Lookup</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center gap-3">
            <Input
              placeholder="Enter Batch ID..."
              value={batchInput}
              onChange={(e) => setBatchInput(e.target.value)}
              className="max-w-sm"
            />
            <Button size="sm" onClick={handleBatchLookup} disabled={batchLoading}>
              {batchLoading ? <RotateCw className="mr-2 h-4 w-4 animate-spin" /> : null}
              Lookup
            </Button>
            {batchId && (
              <>
                <Button size="sm" variant="outline" onClick={() => handleExport(batchId)}>
                  <Download className="mr-2 h-4 w-4" /> Export
                </Button>
                <Button
                  size="sm"
                  variant="destructive"
                  onClick={() => setRevokeTarget({ type: "batch", id: batchId, label: `Batch ${batchId}` })}
                >
                  <Ban className="mr-2 h-4 w-4" /> Revoke Batch
                </Button>
              </>
            )}
          </div>

          {batchCodes.length > 0 && (
            <div className="rounded-md border max-h-80 overflow-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Code</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Activated By</TableHead>
                    <TableHead>Activated At</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {batchCodes.map((c) => (
                    <TableRow key={c._id}>
                      <TableCell className="font-mono text-sm">{c.code}</TableCell>
                      <TableCell>{statusBadge(c.status)}</TableCell>
                      <TableCell className="text-muted-foreground">
                        {c.activatedBy ? c.activatedBy.name : "—"}
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {c.activatedAt ? format(new Date(c.activatedAt), "MMM d, yyyy h:mm a") : "—"}
                      </TableCell>
                      <TableCell className="text-right">
                        {c.status === "available" && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setRevokeTarget({ type: "code", id: c._id, label: c.code })}
                          >
                            <Ban className="h-4 w-4 text-destructive" />
                          </Button>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

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
                    onValueChange={(v) => setGenForm((f) => ({ ...f, targetType: v as "subject" | "bundle", targetId: "" }))}
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
                  <Label>{genForm.targetType === "subject" ? "Subject" : "Bundle"}</Label>
                  <Select value={genForm.targetId} onValueChange={(v) => setGenForm((f) => ({ ...f, targetId: v }))}>
                    <SelectTrigger>
                      <SelectValue placeholder={`Select ${genForm.targetType}`} />
                    </SelectTrigger>
                    <SelectContent>
                      {genForm.targetType === "subject"
                        ? subjects.map((s) => <SelectItem key={s._id} value={s._id}>{s.title}</SelectItem>)
                        : bundles.map((b) => <SelectItem key={b._id} value={b._id}>{b.name}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
              </>
            ) : (
              <>
                <div className="space-y-2">
                  <Label>Exam</Label>
                  <Select value={genForm.targetId} onValueChange={(v) => setGenForm((f) => ({ ...f, targetId: v }))}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select exam" />
                    </SelectTrigger>
                    <SelectContent>
                      {exams.map((e) => <SelectItem key={e._id} value={e._id}>{e.title}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Usage Type</Label>
                  <Select
                    value={genForm.usageType}
                    onValueChange={(v) => setGenForm((f) => ({ ...f, usageType: v as "single" | "multi" }))}
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
                      onChange={(e) => setGenForm((f) => ({ ...f, maxUses: +e.target.value }))}
                    />
                  </div>
                )}
                <div className="space-y-2">
                  <Label>Time Limit (minutes, 0 = no limit)</Label>
                  <Input
                    type="number"
                    min={0}
                    value={genForm.timeLimitMinutes}
                    onChange={(e) => setGenForm((f) => ({ ...f, timeLimitMinutes: +e.target.value }))}
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
                onChange={(e) => setGenForm((f) => ({ ...f, quantity: +e.target.value }))}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setGenDialog(false)}>Cancel</Button>
            <Button onClick={handleGenerate} disabled={generating || !genForm.targetId || genForm.quantity < 1}>
              {generating ? <RotateCw className="mr-2 h-4 w-4 animate-spin" /> : null}
              Generate {genForm.quantity} Codes
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Revoke Confirmation */}
      <AlertDialog open={!!revokeTarget} onOpenChange={() => setRevokeTarget(null)}>
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
            <AlertDialogAction onClick={handleRevoke} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              Revoke
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
