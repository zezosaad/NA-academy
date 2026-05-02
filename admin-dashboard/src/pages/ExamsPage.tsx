import { useState, useEffect, useCallback } from "react"
import {
  Plus,
  Pencil,
  Trash2,
  RotateCw,
  ChevronDown,
  ChevronUp,
  GripVertical,
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
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { LoadingState } from "@/components/LoadingState"
import { EmptyState } from "@/components/EmptyState"
import { useAppModal } from "@/components/AppModalProvider"
import { api } from "@/services/api"
import type { Exam, Subject, Question, QuestionOption, ExamAccessMode, ExamTimingMode } from "@/types"
import { format } from "date-fns"

const getOptionLabel = (index: number) => {
  let value = index
  let label = ""

  do {
    label = String.fromCharCode(65 + (value % 26)) + label
    value = Math.floor(value / 26) - 1
  } while (value >= 0)

  return label
}

const relabelOptions = (options: QuestionOption[]) =>
  options.map((option, index) => ({
    ...option,
    label: getOptionLabel(index),
  }))

const createQuestionOptions = (count = 4): QuestionOption[] =>
  Array.from({ length: count }, (_, index) => ({
    label: getOptionLabel(index),
    text: "",
  }))

const createEmptyQuestion = (order = 0): Question => ({
  text: "",
  options: createQuestionOptions(),
  correctOption: "A",
  timeLimitSeconds: 60,
  order,
})

const getExamAccessMode = (exam?: Pick<Exam, "accessMode" | "hasFreeSection"> | null): ExamAccessMode => {
  if (exam?.accessMode) return exam.accessMode
  return exam?.hasFreeSection ? "free_section" : "code_required"
}

const toDateTimeLocalValue = (value?: string) => {
  if (!value) return ""
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ""
  const offsetMs = date.getTimezoneOffset() * 60 * 1000
  return new Date(date.getTime() - offsetMs).toISOString().slice(0, 16)
}

const fromDateTimeLocalValue = (value: string) => {
  if (!value) return undefined
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? undefined : date.toISOString()
}

export function ExamsPage() {
  const { showError } = useAppModal()
  const [exams, setExams] = useState<Exam[]>([])
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)

  // Exam form
  const [examDialog, setExamDialog] = useState(false)
  const [editingExam, setEditingExam] = useState<Exam | null>(null)
  const [examForm, setExamForm] = useState({
    title: "",
    subjectId: "",
    accessMode: "code_required" as ExamAccessMode,
    timingMode: "per_question" as ExamTimingMode,
    examTimeLimitMinutes: 30,
    availableFrom: "",
    availableUntil: "",
    hasFreeSection: false,
    freeQuestionCount: 0,
    freeAttemptLimit: 1,
    questions: [createEmptyQuestion()] as Question[],
  })
  const [saving, setSaving] = useState(false)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [expandedQ, setExpandedQ] = useState<number | null>(0)

  const limit = 20

  const fetchData = useCallback(async () => {
    setLoading(true)
    try {
      const [examRes, subRes] = await Promise.all([
        api.getExams({ page, limit }),
        api.getSubjects({ limit: 100 }),
      ])
      setExams(examRes.data)
      setTotal(examRes.total)
      setSubjects(subRes.data)
    } catch {
      //
    } finally {
      setLoading(false)
    }
  }, [page])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const openForm = (exam?: Exam) => {
    if (exam) {
      setEditingExam(exam)
      setExamForm({
        title: exam.title,
        subjectId: typeof exam.subjectId === "string" ? exam.subjectId : exam.subjectId._id,
        accessMode: getExamAccessMode(exam),
        timingMode: exam.timingMode ?? "per_question",
        examTimeLimitMinutes: exam.examTimeLimitMinutes ?? 30,
        availableFrom: toDateTimeLocalValue(exam.availableFrom),
        availableUntil: toDateTimeLocalValue(exam.availableUntil),
        hasFreeSection: exam.hasFreeSection,
        freeQuestionCount: exam.freeQuestionCount ?? 0,
        freeAttemptLimit: exam.freeAttemptLimit ?? 1,
        questions: exam.questions.map((q) => ({
          ...q,
          options: relabelOptions(q.options.map((option) => ({ ...option }))),
        })),
      })
    } else {
      setEditingExam(null)
      setExamForm({
        title: "",
        subjectId: "",
        accessMode: "code_required",
        timingMode: "per_question",
        examTimeLimitMinutes: 30,
        availableFrom: "",
        availableUntil: "",
        hasFreeSection: false,
        freeQuestionCount: 0,
        freeAttemptLimit: 1,
        questions: [createEmptyQuestion()],
      })
    }
    setExpandedQ(0)
    setExamDialog(true)
  }

  const saveExam = async () => {
    for (let i = 0; i < examForm.questions.length; i++) {
      const q = examForm.questions[i]
      const normalizedLabels = q.options.map((o) => String(o.label || "").trim().toUpperCase())
      const uniqueLabels = new Set(normalizedLabels)

      if (normalizedLabels.some((label) => !label)) {
        showError(`Question ${i + 1} has an empty option label`)
        return
      }

      if (uniqueLabels.size !== normalizedLabels.length) {
        showError(`Question ${i + 1} has duplicate option labels. Each option label must be unique.`)
        return
      }

      if (q.options.length < 2) {
        showError(`Question ${i + 1} must have at least 2 options`)
        return
      }

      if (!normalizedLabels.includes(String(q.correctOption || "").trim().toUpperCase())) {
        showError(`Question ${i + 1} has an invalid correct option`)
        return
      }
    }

    if (examForm.accessMode === "free_section") {
      if (examForm.freeQuestionCount < 1) {
        showError("Free section question count must be at least 1")
        return
      }

      if (examForm.freeQuestionCount > examForm.questions.length) {
        showError("Free section question count cannot exceed the total number of questions")
        return
      }
    }

    if (examForm.accessMode !== "code_required" && examForm.freeAttemptLimit < 1) {
      showError("Free attempt limit must be at least 1")
      return
    }

    if (examForm.timingMode === "whole_exam" && examForm.examTimeLimitMinutes < 1) {
      showError("Whole exam duration must be at least 1 minute")
      return
    }

    if (examForm.timingMode === "per_question") {
      const invalidQuestionIndex = examForm.questions.findIndex((q) => q.timeLimitSeconds < 5)
      if (invalidQuestionIndex >= 0) {
        showError(`Question ${invalidQuestionIndex + 1} time must be at least 5 seconds`)
        return
      }
    }

    const availableFrom = fromDateTimeLocalValue(examForm.availableFrom)
    const availableUntil = fromDateTimeLocalValue(examForm.availableUntil)
    if (availableFrom && availableUntil && new Date(availableFrom) >= new Date(availableUntil)) {
      showError("Exam availability start must be before the end")
      return
    }

    setSaving(true)
    try {
      const data = {
        title: examForm.title,
        subjectId: examForm.subjectId,
        accessMode: examForm.accessMode,
        timingMode: examForm.timingMode,
        examTimeLimitMinutes:
          examForm.timingMode === "whole_exam" ? examForm.examTimeLimitMinutes : undefined,
        availableFrom: availableFrom ?? null,
        availableUntil: availableUntil ?? null,
        hasFreeSection: examForm.accessMode === "free_section",
        freeQuestionCount:
          examForm.accessMode === "free_section" ? examForm.freeQuestionCount : undefined,
        freeAttemptLimit:
          examForm.accessMode === "code_required" ? undefined : examForm.freeAttemptLimit,
        questions: examForm.questions.map((q, i) => ({ ...q, order: i })),
      }
      if (editingExam) {
        await api.updateExam(editingExam._id, data)
      } else {
        await api.createExam(data)
      }
      setExamDialog(false)
      fetchData()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Failed to save exam")
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!deleteId) return
    try {
      await api.deleteExam(deleteId)
      setDeleteId(null)
      fetchData()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Delete failed")
    }
  }

  // Question helpers
  const updateQuestion = (idx: number, partial: Partial<Question>) => {
    setExamForm((f) => ({
      ...f,
      questions: f.questions.map((q, i) => (i === idx ? { ...q, ...partial } : q)),
    }))
  }

  const updateOption = (qIdx: number, oIdx: number, text: string) => {
    setExamForm((f) => ({
      ...f,
      questions: f.questions.map((q, i) =>
        i === qIdx
          ? { ...q, options: q.options.map((o, j) => (j === oIdx ? { ...o, text } : o)) }
          : q
      ),
    }))
  }

  const addOption = (qIdx: number) => {
    setExamForm((f) => ({
      ...f,
      questions: f.questions.map((q, i) => {
        if (i !== qIdx) return q
        const options = relabelOptions([...q.options, { label: "", text: "" }])
        return { ...q, options }
      }),
    }))
  }

  const removeOption = (qIdx: number, oIdx: number) => {
    setExamForm((f) => ({
      ...f,
      questions: f.questions.map((q, i) => {
        if (i !== qIdx || q.options.length <= 2) return q

        const nextOptions = relabelOptions(q.options.filter((_, index) => index !== oIdx))
        const previousCorrectIndex = q.options.findIndex((option) => option.label === q.correctOption)
        const nextCorrectOption =
          previousCorrectIndex === oIdx
            ? nextOptions[0]?.label ?? "A"
            : nextOptions[Math.max(0, previousCorrectIndex - (oIdx < previousCorrectIndex ? 1 : 0))]?.label ?? nextOptions[0]?.label ?? "A"

        return {
          ...q,
          options: nextOptions,
          correctOption: nextCorrectOption,
        }
      }),
    }))
  }

  const addQuestion = () => {
    setExamForm((f) => ({
      ...f,
      questions: [...f.questions, createEmptyQuestion(f.questions.length)],
    }))
    setExpandedQ(examForm.questions.length)
  }

  const removeQuestion = (idx: number) => {
    setExamForm((f) => ({
      ...f,
      questions: f.questions.filter((_, i) => i !== idx),
    }))
    setExpandedQ(null)
  }

  const totalPages = Math.ceil(total / limit)

  if (loading) return <LoadingState />

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <span className="text-sm text-muted-foreground">{total} exams</span>
        <Button size="sm" onClick={() => openForm()}>
          <Plus className="mr-2 h-4 w-4" />
          New Exam
        </Button>
      </div>

      {exams.length === 0 ? (
        <EmptyState title="No exams" description="Create your first exam." />
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Title</TableHead>
                <TableHead>Subject</TableHead>
                <TableHead>Questions</TableHead>
                <TableHead>Timing</TableHead>
                <TableHead>Availability</TableHead>
                <TableHead>Access</TableHead>
                <TableHead>Created</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {exams.map((e) => (
                <TableRow key={e._id}>
                  <TableCell className="font-medium">{e.title}</TableCell>
                  <TableCell className="text-muted-foreground">
                    {typeof e.subjectId === "string"
                      ? subjects.find((s) => s._id === e.subjectId)?.title || e.subjectId
                      : e.subjectId.title}
                  </TableCell>
                  <TableCell>{e.questions.length}</TableCell>
                  <TableCell>
                    {e.timingMode === "whole_exam" ? (
                      <span className="text-sm text-muted-foreground">
                        {e.examTimeLimitMinutes ?? 0} min total
                      </span>
                    ) : (
                      <span className="text-sm text-muted-foreground">Per question</span>
                    )}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {e.availableFrom || e.availableUntil ? (
                      <span className="text-sm">
                        {e.availableFrom ? format(new Date(e.availableFrom), "MMM d, h:mm a") : "Now"}
                        {" to "}
                        {e.availableUntil ? format(new Date(e.availableUntil), "MMM d, h:mm a") : "No end"}
                      </span>
                    ) : (
                      <span className="text-sm">Always open</span>
                    )}
                  </TableCell>
                  <TableCell>
                    {getExamAccessMode(e) === "free_section" ? (
                      <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">
                        {e.freeQuestionCount} free questions
                      </Badge>
                    ) : getExamAccessMode(e) === "full_exam_free_attempts" ? (
                      <Badge className="bg-amber-500/10 text-amber-700 border-amber-200">
                        {e.freeAttemptLimit} free attempts
                      </Badge>
                    ) : (
                      <Badge variant="outline">Code required</Badge>
                    )}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {format(new Date(e.createdAt), "MMM d, yyyy")}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-1">
                      <Button variant="ghost" size="sm" onClick={() => openForm(e)}>
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="sm" onClick={() => setDeleteId(e._id)}>
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
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
          <p className="text-sm text-muted-foreground">Page {page} of {totalPages}</p>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
              Previous
            </Button>
            <Button variant="outline" size="sm" disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>
              Next
            </Button>
          </div>
        </div>
      )}

      {/* Exam Form Dialog */}
      <Dialog open={examDialog} onOpenChange={setExamDialog}>
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-auto">
          <DialogHeader>
            <DialogTitle>{editingExam ? "Edit Exam" : "New Exam"}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            {/* Basic info */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Title</Label>
                <Input value={examForm.title} onChange={(e) => setExamForm((f) => ({ ...f, title: e.target.value }))} />
              </div>
              <div className="space-y-2">
                <Label>Subject</Label>
                <Select value={examForm.subjectId} onValueChange={(v) => setExamForm((f) => ({ ...f, subjectId: v }))}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select subject" />
                  </SelectTrigger>
                  <SelectContent>
                    {subjects.map((s) => (
                      <SelectItem key={s._id} value={s._id}>{s.title}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="rounded-md border p-3 space-y-3">
              <div className="space-y-2">
                <Label>Timing</Label>
                <Select
                  value={examForm.timingMode}
                  onValueChange={(value: ExamTimingMode) =>
                    setExamForm((f) => ({ ...f, timingMode: value }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="per_question">Time for each question</SelectItem>
                    <SelectItem value="whole_exam">One timer for the whole exam</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {examForm.timingMode === "whole_exam" && (
                <div className="flex items-center gap-2">
                  <Label className="text-xs text-muted-foreground">Exam duration:</Label>
                  <Input
                    type="number"
                    className="w-24 h-8"
                    min={1}
                    value={examForm.examTimeLimitMinutes}
                    onChange={(e) =>
                      setExamForm((f) => ({ ...f, examTimeLimitMinutes: +e.target.value }))
                    }
                  />
                  <span className="text-xs text-muted-foreground">minutes</span>
                </div>
              )}
            </div>

            <div className="rounded-md border p-3 space-y-3">
              <Label>Availability Window</Label>
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-2">
                  <Label className="text-xs text-muted-foreground">Starts at</Label>
                  <Input
                    type="datetime-local"
                    value={examForm.availableFrom}
                    onChange={(e) =>
                      setExamForm((f) => ({ ...f, availableFrom: e.target.value }))
                    }
                  />
                </div>
                <div className="space-y-2">
                  <Label className="text-xs text-muted-foreground">Ends at</Label>
                  <Input
                    type="datetime-local"
                    value={examForm.availableUntil}
                    onChange={(e) =>
                      setExamForm((f) => ({ ...f, availableUntil: e.target.value }))
                    }
                  />
                </div>
              </div>
            </div>

            <div className="rounded-md border p-3 space-y-3">
              <div className="space-y-2">
                <Label>Access Mode</Label>
                <Select
                  value={examForm.accessMode}
                  onValueChange={(value: ExamAccessMode) =>
                    setExamForm((f) => ({
                      ...f,
                      accessMode: value,
                      hasFreeSection: value === "free_section",
                      freeQuestionCount:
                        value === "free_section"
                          ? Math.max(f.freeQuestionCount || 1, 1)
                          : 0,
                      freeAttemptLimit:
                        value === "code_required" ? 1 : Math.max(f.freeAttemptLimit || 1, 1),
                    }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="code_required">Code required</SelectItem>
                    <SelectItem value="free_section">Free section</SelectItem>
                    <SelectItem value="full_exam_free_attempts">Full exam free attempts</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {examForm.accessMode === "free_section" && (
                <div className="flex items-center gap-2">
                  <Label className="text-xs text-muted-foreground">Free questions:</Label>
                  <Input
                    type="number"
                    className="w-20 h-8"
                    min={1}
                    max={examForm.questions.length}
                    value={examForm.freeQuestionCount}
                    onChange={(e) =>
                      setExamForm((f) => ({ ...f, freeQuestionCount: +e.target.value }))
                    }
                  />
                </div>
              )}

              {examForm.accessMode !== "code_required" && (
                <div className="flex items-center gap-2">
                  <Label className="text-xs text-muted-foreground">Free attempts:</Label>
                  <Input
                    type="number"
                    className="w-20 h-8"
                    min={1}
                    value={examForm.freeAttemptLimit}
                    onChange={(e) =>
                      setExamForm((f) => ({ ...f, freeAttemptLimit: +e.target.value }))
                    }
                  />
                </div>
              )}
            </div>

            {/* Questions */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label className="text-base">Questions ({examForm.questions.length})</Label>
                <Button variant="outline" size="sm" onClick={addQuestion}>
                  <Plus className="mr-2 h-3 w-3" /> Add Question
                </Button>
              </div>
              <div className="space-y-2">
                {examForm.questions.map((q, qi) => (
                  <Card key={qi}>
                    <CardHeader
                      className="cursor-pointer py-3 px-4"
                      onClick={() => setExpandedQ(expandedQ === qi ? null : qi)}
                    >
                      <div className="flex items-center gap-2">
                        <GripVertical className="h-4 w-4 text-muted-foreground" />
                        <CardTitle className="text-sm flex-1">
                          Q{qi + 1}: {q.text || "(empty)"}
                        </CardTitle>
                        {expandedQ === qi ? (
                          <ChevronUp className="h-4 w-4" />
                        ) : (
                          <ChevronDown className="h-4 w-4" />
                        )}
                      </div>
                    </CardHeader>
                    {expandedQ === qi && (
                      <CardContent className="space-y-3 pt-0">
                        <div className="space-y-2">
                          <Label className="text-xs">Question Text</Label>
                          <Input
                            value={q.text}
                            onChange={(e) => updateQuestion(qi, { text: e.target.value })}
                          />
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                          {q.options.map((o, oi) => (
                            <div key={oi} className="flex items-center gap-2">
                              <span className="text-xs font-bold text-muted-foreground w-4">{o.label}</span>
                              <Input
                                className="h-8 text-sm"
                                placeholder={`Option ${o.label}`}
                                value={o.text}
                                onChange={(e) => updateOption(qi, oi, e.target.value)}
                              />
                              {q.options.length > 2 && (
                                <Button
                                  type="button"
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => removeOption(qi, oi)}
                                >
                                  <Trash2 className="h-4 w-4 text-destructive" />
                                </Button>
                              )}
                            </div>
                          ))}
                        </div>
                        <div className="flex items-center gap-4">
                          <Button type="button" variant="outline" size="sm" onClick={() => addOption(qi)}>
                            <Plus className="mr-2 h-3 w-3" /> Add Option
                          </Button>
                          <div className="flex items-center gap-2">
                            <Label className="text-xs">Correct:</Label>
                            <Select
                              value={q.correctOption}
                              onValueChange={(v) => updateQuestion(qi, { correctOption: v })}
                            >
                              <SelectTrigger className="w-16 h-8">
                                <SelectValue />
                              </SelectTrigger>
                              <SelectContent>
                                {q.options.map((o) => (
                                  <SelectItem key={o.label} value={o.label}>{o.label}</SelectItem>
                                ))}
                              </SelectContent>
                            </Select>
                          </div>
                          <div className="flex items-center gap-2">
                            <Label className="text-xs">Time (s):</Label>
                            <Input
                              type="number"
                              className="w-20 h-8"
                              disabled={examForm.timingMode === "whole_exam"}
                              value={q.timeLimitSeconds}
                              onChange={(e) => updateQuestion(qi, { timeLimitSeconds: +e.target.value })}
                            />
                            {examForm.timingMode === "whole_exam" && (
                              <span className="text-xs text-muted-foreground">not used</span>
                            )}
                          </div>
                          {examForm.questions.length > 1 && (
                            <Button variant="ghost" size="sm" className="ml-auto" onClick={() => removeQuestion(qi)}>
                              <Trash2 className="h-4 w-4 text-destructive" />
                            </Button>
                          )}
                        </div>
                      </CardContent>
                    )}
                  </Card>
                ))}
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setExamDialog(false)}>Cancel</Button>
            <Button
              onClick={saveExam}
              disabled={saving || !examForm.title || !examForm.subjectId || examForm.questions.length === 0}
            >
              {saving ? <RotateCw className="mr-2 h-4 w-4 animate-spin" /> : null}
              {editingExam ? "Update" : "Create"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteId} onOpenChange={() => setDeleteId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this exam?</AlertDialogTitle>
            <AlertDialogDescription>This action cannot be undone.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
