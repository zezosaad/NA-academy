import { useState, useEffect, useCallback, useMemo, useRef } from "react"
import {
  Plus,
  Pencil,
  Trash2,
  RotateCw,
  ChevronDown,
  ChevronUp,
  GripVertical,
  Users,
  Search,
  X,
  Unlock,
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
import type {
  Exam,
  Subject,
  Question,
  QuestionOption,
  ExamAccessMode,
  ExamTimingMode,
  AssignableStudent,
} from "@/types"
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

const accessModeLabels: Record<ExamAccessMode, string> = {
  code_required: "Code required",
  free_section: "Free section",
  full_exam_free_attempts: "Full exam free attempts",
  free: "Free (open to all)",
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
    assignedStudents: [] as AssignableStudent[],
    questions: [createEmptyQuestion()] as Question[],
  })
  const [saving, setSaving] = useState(false)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [expandedQ, setExpandedQ] = useState<number | null>(0)
  const [studentSearchTerm, setStudentSearchTerm] = useState("")
  const [studentSearchResults, setStudentSearchResults] = useState<AssignableStudent[]>([])
  const [studentSearchLoading, setStudentSearchLoading] = useState(false)
  const studentSearchTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const [permitsDialogExam, setPermitsDialogExam] = useState<Exam | null>(null)

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
      const assigned: AssignableStudent[] =
        exam.assignedStudents && exam.assignedStudents.length > 0
          ? exam.assignedStudents
          : (exam.assignedStudentIds ?? []).map((id) => ({ id, name: id, email: "" }))
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
        assignedStudents: assigned,
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
        assignedStudents: [],
        questions: [createEmptyQuestion()],
      })
    }
    setStudentSearchTerm("")
    setStudentSearchResults([])
    setExpandedQ(0)
    setExamDialog(true)
  }

  const assignedIdSet = useMemo(
    () => new Set(examForm.assignedStudents.map((s) => s.id)),
    [examForm.assignedStudents],
  )

  useEffect(() => {
    if (studentSearchTimer.current) clearTimeout(studentSearchTimer.current)
    const term = studentSearchTerm.trim()
    if (!term) {
      setStudentSearchResults([])
      setStudentSearchLoading(false)
      return
    }
    setStudentSearchLoading(true)
    studentSearchTimer.current = setTimeout(async () => {
      try {
        const results = await api.searchUsers(term, 10)
        setStudentSearchResults(
          results
            .filter((u) => u.role === "student")
            .map((u) => ({ id: u.id, name: u.name, email: u.email })),
        )
      } catch {
        setStudentSearchResults([])
      } finally {
        setStudentSearchLoading(false)
      }
    }, 300)
    return () => {
      if (studentSearchTimer.current) clearTimeout(studentSearchTimer.current)
    }
  }, [studentSearchTerm])

  const addAssignedStudent = (student: AssignableStudent) => {
    setExamForm((f) =>
      assignedIdSet.has(student.id)
        ? f
        : { ...f, assignedStudents: [...f.assignedStudents, student] },
    )
    setStudentSearchTerm("")
    setStudentSearchResults([])
  }

  const removeAssignedStudent = (id: string) => {
    setExamForm((f) => ({
      ...f,
      assignedStudents: f.assignedStudents.filter((s) => s.id !== id),
    }))
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

    if (
      (examForm.accessMode === "free_section" ||
        examForm.accessMode === "full_exam_free_attempts") &&
      examForm.freeAttemptLimit < 1
    ) {
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
          examForm.accessMode === "code_required" || examForm.accessMode === "free"
            ? undefined
            : examForm.freeAttemptLimit,
        assignedStudentIds: examForm.assignedStudents.map((s) => s.id),
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
                    <div className="flex flex-col gap-1">
                      {getExamAccessMode(e) === "free_section" ? (
                        <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">
                          {e.freeQuestionCount} free questions
                        </Badge>
                      ) : getExamAccessMode(e) === "full_exam_free_attempts" ? (
                        <Badge className="bg-amber-500/10 text-amber-700 border-amber-200">
                          Free attempt
                        </Badge>
                      ) : getExamAccessMode(e) === "free" ? (
                        <Badge className="bg-blue-500/10 text-blue-600 border-blue-200">
                          Free
                        </Badge>
                      ) : (
                        <Badge variant="outline">Code required</Badge>
                      )}
                      {e.assignedStudentIds && e.assignedStudentIds.length > 0 && (
                        <Badge variant="secondary" className="gap-1">
                          <Users className="h-3 w-3" />
                          {e.assignedStudentIds.length} targeted
                        </Badge>
                      )}
                    </div>
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {format(new Date(e.createdAt), "MMM d, yyyy")}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        title="Manage retake permits"
                        onClick={() => setPermitsDialogExam(e)}
                      >
                        <Unlock className="h-4 w-4" />
                      </Button>
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
                        value === "code_required" || value === "free"
                          ? 1
                          : Math.max(f.freeAttemptLimit || 1, 1),
                    }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="code_required">Code required</SelectItem>
                    <SelectItem value="free">Free (open to all)</SelectItem>
                    <SelectItem value="free_section">Free section</SelectItem>
                    <SelectItem value="full_exam_free_attempts">Full exam free attempts</SelectItem>
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground">
                  Every exam can be taken only once per student. Use the retake button on the exam
                  list to grant a single retake to a specific student.
                </p>
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
            </div>

            {/* Targeted students */}
            <div className="rounded-md border p-3 space-y-3">
              <div className="flex items-center gap-2">
                <Users className="h-4 w-4 text-muted-foreground" />
                <Label>Targeted Students (optional)</Label>
              </div>
              <p className="text-xs text-muted-foreground">
                If you add students here, only they will see and access this exam. Leave empty to
                make it visible according to subject subscriptions and access mode.
              </p>
              <div className="relative">
                <div className="flex items-center gap-2 rounded-md border px-2">
                  <Search className="h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="Search students by name or email"
                    className="border-0 focus-visible:ring-0 focus-visible:ring-offset-0 h-9"
                    value={studentSearchTerm}
                    onChange={(e) => setStudentSearchTerm(e.target.value)}
                  />
                </div>
                {studentSearchTerm.trim() && (
                  <div className="absolute z-10 mt-1 w-full rounded-md border bg-popover shadow-md max-h-56 overflow-auto">
                    {studentSearchLoading ? (
                      <div className="px-3 py-2 text-sm text-muted-foreground">Searching…</div>
                    ) : studentSearchResults.length === 0 ? (
                      <div className="px-3 py-2 text-sm text-muted-foreground">No students found</div>
                    ) : (
                      studentSearchResults.map((s) => {
                        const alreadyAdded = assignedIdSet.has(s.id)
                        return (
                          <button
                            key={s.id}
                            type="button"
                            disabled={alreadyAdded}
                            className="w-full text-left px-3 py-2 text-sm hover:bg-accent disabled:opacity-50 disabled:cursor-not-allowed flex flex-col"
                            onClick={() => addAssignedStudent(s)}
                          >
                            <span className="font-medium">{s.name}</span>
                            <span className="text-xs text-muted-foreground">{s.email}</span>
                          </button>
                        )
                      })
                    )}
                  </div>
                )}
              </div>
              {examForm.assignedStudents.length > 0 && (
                <div className="flex flex-wrap gap-2">
                  {examForm.assignedStudents.map((s) => (
                    <Badge key={s.id} variant="secondary" className="gap-1 pl-2 pr-1 py-1">
                      <span className="text-xs">{s.name || s.id}</span>
                      <button
                        type="button"
                        onClick={() => removeAssignedStudent(s.id)}
                        className="ml-1 rounded-full hover:bg-muted-foreground/10 p-0.5"
                        aria-label="Remove"
                      >
                        <X className="h-3 w-3" />
                      </button>
                    </Badge>
                  ))}
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

      {/* Retake Permits Dialog */}
      <RetakePermitsDialog
        exam={permitsDialogExam}
        onClose={() => setPermitsDialogExam(null)}
      />

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

interface RetakePermit {
  _id: string
  status: "active" | "used" | "revoked"
  usedAt?: string
  note?: string
  createdAt: string
  studentId: { _id: string; name: string; email: string } | string
  grantedBy: { _id: string; name: string; email: string } | string
}

function RetakePermitsDialog({
  exam,
  onClose,
}: {
  exam: Exam | null
  onClose: () => void
}) {
  const { showError } = useAppModal()
  const [permits, setPermits] = useState<RetakePermit[]>([])
  const [loading, setLoading] = useState(false)
  const [grantSearch, setGrantSearch] = useState("")
  const [grantResults, setGrantResults] = useState<AssignableStudent[]>([])
  const [grantNote, setGrantNote] = useState("")
  const [granting, setGranting] = useState<string | null>(null)
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const refresh = useCallback(async () => {
    if (!exam) return
    setLoading(true)
    try {
      const data = await api.listExamRetakePermits(exam._id)
      setPermits(data as RetakePermit[])
    } catch (err) {
      showError(err instanceof Error ? err.message : "Failed to load retake permits")
    } finally {
      setLoading(false)
    }
  }, [exam, showError])

  useEffect(() => {
    if (exam) {
      refresh()
    } else {
      setPermits([])
      setGrantSearch("")
      setGrantResults([])
      setGrantNote("")
    }
  }, [exam, refresh])

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current)
    const term = grantSearch.trim()
    if (!term) {
      setGrantResults([])
      return
    }
    debounceRef.current = setTimeout(async () => {
      try {
        const results = await api.searchUsers(term, 10)
        setGrantResults(
          results
            .filter((u) => u.role === "student")
            .map((u) => ({ id: u.id, name: u.name, email: u.email })),
        )
      } catch {
        setGrantResults([])
      }
    }, 300)
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current)
    }
  }, [grantSearch])

  const handleGrant = async (studentId: string) => {
    if (!exam) return
    setGranting(studentId)
    try {
      await api.grantExamRetakePermit(exam._id, studentId, grantNote.trim() || undefined)
      setGrantSearch("")
      setGrantResults([])
      setGrantNote("")
      await refresh()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Failed to grant retake")
    } finally {
      setGranting(null)
    }
  }

  const handleRevoke = async (permitId: string) => {
    try {
      await api.revokeExamRetakePermit(permitId)
      await refresh()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Failed to revoke permit")
    }
  }

  const studentName = (s: RetakePermit["studentId"]) =>
    typeof s === "string" ? s : `${s.name} <${s.email}>`

  return (
    <Dialog open={!!exam} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Retake permits — {exam?.title}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div className="rounded-md border p-3 space-y-2">
            <Label className="text-sm">Grant a one-time retake to a student</Label>
            <div className="relative">
              <div className="flex items-center gap-2 rounded-md border px-2">
                <Search className="h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search student by name or email"
                  className="border-0 focus-visible:ring-0 focus-visible:ring-offset-0 h-9"
                  value={grantSearch}
                  onChange={(e) => setGrantSearch(e.target.value)}
                />
              </div>
              {grantSearch.trim() && grantResults.length > 0 && (
                <div className="absolute z-10 mt-1 w-full rounded-md border bg-popover shadow-md max-h-56 overflow-auto">
                  {grantResults.map((s) => (
                    <button
                      key={s.id}
                      type="button"
                      disabled={granting === s.id}
                      className="w-full text-left px-3 py-2 text-sm hover:bg-accent disabled:opacity-50 flex flex-col"
                      onClick={() => handleGrant(s.id)}
                    >
                      <span className="font-medium">{s.name}</span>
                      <span className="text-xs text-muted-foreground">{s.email}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>
            <Input
              placeholder="Optional note (reason for the retake)"
              value={grantNote}
              onChange={(e) => setGrantNote(e.target.value)}
              className="h-9"
            />
          </div>

          <div>
            <h4 className="text-sm font-medium mb-2">Existing permits</h4>
            {loading ? (
              <LoadingState />
            ) : permits.length === 0 ? (
              <EmptyState title="No permits granted" description="Grant a retake using the form above." />
            ) : (
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Student</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Granted</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {permits.map((p) => (
                      <TableRow key={p._id}>
                        <TableCell className="text-sm">{studentName(p.studentId)}</TableCell>
                        <TableCell>
                          {p.status === "active" ? (
                            <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">
                              Active
                            </Badge>
                          ) : p.status === "used" ? (
                            <Badge variant="outline">Used</Badge>
                          ) : (
                            <Badge variant="outline" className="text-muted-foreground">
                              Revoked
                            </Badge>
                          )}
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {format(new Date(p.createdAt), "MMM d, yyyy")}
                        </TableCell>
                        <TableCell className="text-right">
                          {p.status === "active" && (
                            <Button variant="ghost" size="sm" onClick={() => handleRevoke(p._id)}>
                              Revoke
                            </Button>
                          )}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Close
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
