import { useState, useEffect, useCallback } from "react"
import { useParams, useNavigate } from "react-router-dom"
import {
  ArrowLeft,
  Plus,
  Pencil,
  Trash2,
  RotateCw,
  BookOpen,
  Video,
  Upload,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import { Textarea } from "@/components/ui/textarea"
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
import { Progress } from "@/components/ui/progress"
import { LoadingState } from "@/components/LoadingState"
import { EmptyState } from "@/components/EmptyState"
import { useAppModal } from "@/components/AppModalProvider"
import { api } from "@/services/api"
import type { Subject, Lesson, MediaAsset } from "@/types"

export function SubjectDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { showError } = useAppModal()

  const [subject, setSubject] = useState<Subject | null>(null)
  const [lessons, setLessons] = useState<Lesson[]>([])
  const [media, setMedia] = useState<MediaAsset[]>([])
  const [loading, setLoading] = useState(true)

  // Lesson form
  const [lessonDialog, setLessonDialog] = useState(false)
  const [editingLesson, setEditingLesson] = useState<Lesson | null>(null)
  const [lessonForm, setLessonForm] = useState({
    title: "",
    description: "",
    order: 0,
    mediaId: "",
  })
  const [videoFile, setVideoFile] = useState<File | null>(null)
  const [uploadProgress, setUploadProgress] = useState<number | null>(null)
  const [saving, setSaving] = useState(false)
  const [deleteLessonId, setDeleteLessonId] = useState<string | null>(null)

  const fetchData = useCallback(async () => {
    if (!id) return
    setLoading(true)
    try {
      const [subjectData, lessonsData, mediaData] = await Promise.all([
        api.getSubject(id),
        api.getLessons(id),
        api.getSubjectMedia(id),
      ])
      setSubject(subjectData)
      setLessons(lessonsData)
      setMedia(mediaData)
    } catch (err) {
      showError(err instanceof Error ? err.message : "Failed to load subject")
    } finally {
      setLoading(false)
    }
  }, [id, showError])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const openLessonForm = (lesson?: Lesson) => {
    if (lesson) {
      setEditingLesson(lesson)
      setLessonForm({
        title: lesson.title,
        description: lesson.description || "",
        order: lesson.order,
        mediaId: lesson.mediaId || "",
      })
    } else {
      setEditingLesson(null)
      setLessonForm({
        title: "",
        description: "",
        order: lessons.length,
        mediaId: "",
      })
    }
    setVideoFile(null)
    setUploadProgress(null)
    setLessonDialog(true)
  }

  const saveLesson = async () => {
    if (!id) return
    setSaving(true)
    try {
      let mediaId = lessonForm.mediaId || undefined

      // If a new video file was picked, upload it first
      if (videoFile) {
        setUploadProgress(0)
        const uploaded = await api.uploadMedia(
          id,
          videoFile,
          "video",
          lessonForm.title || videoFile.name,
          (pct) => setUploadProgress(pct)
        )
        mediaId = uploaded._id
      }

      const payload = {
        title: lessonForm.title,
        description: lessonForm.description || undefined,
        order: lessonForm.order,
        mediaId,
      }

      if (editingLesson) {
        await api.updateLesson(editingLesson._id, payload)
      } else {
        await api.createLesson(id, payload)
      }

      setLessonDialog(false)
      setVideoFile(null)
      setUploadProgress(null)
      await fetchData()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Failed to save lesson")
    } finally {
      setSaving(false)
    }
  }

  const handleDeleteLesson = async () => {
    if (!deleteLessonId) return
    try {
      await api.deleteLesson(deleteLessonId)
      setDeleteLessonId(null)
      await fetchData()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Delete failed")
    }
  }

  if (loading) return <LoadingState />
  if (!subject) {
    return <EmptyState title="Subject not found" description="This subject may have been deleted." />
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start gap-4">
        <Button variant="ghost" size="sm" onClick={() => navigate("/subjects")}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
      </div>

      <div className="rounded-lg border bg-card p-6 space-y-3">
        <div className="flex items-center gap-2">
          <Badge variant="outline">{subject.category}</Badge>
          {subject.isActive ? (
            <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">Active</Badge>
          ) : (
            <Badge variant="secondary">Inactive</Badge>
          )}
        </div>
        <h1 className="text-2xl font-semibold">{subject.title}</h1>
        {subject.description && (
          <p className="text-muted-foreground">{subject.description}</p>
        )}
      </div>

      {/* Lessons section */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <BookOpen className="h-5 w-5" />
            <h2 className="text-lg font-semibold">Lessons</h2>
            <Badge variant="secondary">{lessons.length}</Badge>
          </div>
          <Button size="sm" onClick={() => openLessonForm()}>
            <Plus className="mr-2 h-4 w-4" />
            Add Lesson
          </Button>
        </div>

        {lessons.length === 0 ? (
          <EmptyState
            title="No lessons yet"
            description="Add the first lesson for this subject. Each lesson can include a video."
          />
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12">#</TableHead>
                  <TableHead>Title</TableHead>
                  <TableHead>Video</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {lessons.map((l) => {
                  const linkedMedia = media.find((m) => m._id === l.mediaId)
                  return (
                    <TableRow key={l._id}>
                      <TableCell className="text-muted-foreground">{l.order}</TableCell>
                      <TableCell>
                        <div className="font-medium">{l.title}</div>
                        {l.description && (
                          <p className="text-xs text-muted-foreground line-clamp-1">{l.description}</p>
                        )}
                      </TableCell>
                      <TableCell>
                        {linkedMedia ? (
                          <Badge variant="outline" className="text-xs gap-1">
                            <Video className="h-3 w-3" />
                            {linkedMedia.title || linkedMedia.filename}
                          </Badge>
                        ) : (
                          <span className="text-xs text-muted-foreground">No video</span>
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex items-center justify-end gap-1">
                          <Button variant="ghost" size="sm" onClick={() => openLessonForm(l)} title="Edit">
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setDeleteLessonId(l._id)}
                            title="Delete"
                          >
                            <Trash2 className="h-4 w-4 text-destructive" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  )
                })}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      {/* Lesson Form Dialog */}
      <Dialog open={lessonDialog} onOpenChange={(open) => !saving && setLessonDialog(open)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingLesson ? "Edit Lesson" : "New Lesson"}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Title</Label>
              <Input
                value={lessonForm.title}
                onChange={(e) => setLessonForm((f) => ({ ...f, title: e.target.value }))}
              />
            </div>
            <div className="space-y-2">
              <Label>Description</Label>
              <Textarea
                value={lessonForm.description}
                onChange={(e) => setLessonForm((f) => ({ ...f, description: e.target.value }))}
              />
            </div>
            <div className="space-y-2">
              <Label>Order</Label>
              <Input
                type="number"
                min={0}
                value={lessonForm.order}
                onChange={(e) => setLessonForm((f) => ({ ...f, order: Number(e.target.value) || 0 }))}
              />
            </div>

            <div className="space-y-2">
              <Label>Video</Label>

              {/* Currently linked video (when editing) */}
              {editingLesson && lessonForm.mediaId && !videoFile && (
                <div className="flex items-center justify-between rounded-md border p-2 text-sm">
                  <div className="flex items-center gap-2">
                    <Video className="h-4 w-4" />
                    <span>
                      {media.find((m) => m._id === lessonForm.mediaId)?.title ||
                        media.find((m) => m._id === lessonForm.mediaId)?.filename ||
                        "Linked video"}
                    </span>
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setLessonForm((f) => ({ ...f, mediaId: "" }))}
                  >
                    Remove
                  </Button>
                </div>
              )}

              {/* New file picker */}
              {!lessonForm.mediaId && (
                <>
                  {videoFile ? (
                    <div className="flex items-center justify-between rounded-md border p-2 text-sm">
                      <div className="flex items-center gap-2">
                        <Video className="h-4 w-4" />
                        <span className="truncate max-w-[260px]">{videoFile.name}</span>
                        <span className="text-xs text-muted-foreground">
                          ({(videoFile.size / (1024 * 1024)).toFixed(1)} MB)
                        </span>
                      </div>
                      <Button variant="ghost" size="sm" onClick={() => setVideoFile(null)}>
                        Remove
                      </Button>
                    </div>
                  ) : (
                    <Button asChild variant="outline" size="sm" className="w-full">
                      <label className="cursor-pointer">
                        <Upload className="mr-2 h-4 w-4" />
                        Choose video file
                        <input
                          type="file"
                          className="hidden"
                          accept="video/*"
                          onChange={(e) => {
                            const f = e.target.files?.[0]
                            if (f) setVideoFile(f)
                            e.target.value = ""
                          }}
                        />
                      </label>
                    </Button>
                  )}

                  {/* Or pick existing media for the subject */}
                  {media.filter((m) => m.mediaType === "video").length > 0 && !videoFile && (
                    <details className="text-xs">
                      <summary className="cursor-pointer text-muted-foreground hover:text-foreground">
                        Or pick from existing videos
                      </summary>
                      <select
                        className="mt-2 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                        value={lessonForm.mediaId}
                        onChange={(e) => setLessonForm((f) => ({ ...f, mediaId: e.target.value }))}
                      >
                        <option value="">— None —</option>
                        {media
                          .filter((m) => m.mediaType === "video")
                          .map((m) => (
                            <option key={m._id} value={m._id}>
                              {m.title || m.filename}
                            </option>
                          ))}
                      </select>
                    </details>
                  )}
                </>
              )}

              {uploadProgress !== null && (
                <div>
                  <Progress value={uploadProgress} className="h-2" />
                  <p className="mt-1 text-xs text-muted-foreground">
                    Uploading… {uploadProgress}%
                  </p>
                </div>
              )}
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setLessonDialog(false)} disabled={saving}>
              Cancel
            </Button>
            <Button onClick={saveLesson} disabled={saving || !lessonForm.title}>
              {saving ? <RotateCw className="mr-2 h-4 w-4 animate-spin" /> : null}
              {editingLesson ? "Update" : "Create"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete confirmation */}
      <AlertDialog open={!!deleteLessonId} onOpenChange={() => setDeleteLessonId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this lesson?</AlertDialogTitle>
            <AlertDialogDescription>This action cannot be undone.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDeleteLesson}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
