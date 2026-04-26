import { useState, useEffect, useCallback } from "react"
import { useNavigate } from "react-router-dom"
import { Plus, Pencil, Trash2, RotateCw, ChevronRight } from "lucide-react"
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { LoadingState } from "@/components/LoadingState"
import { EmptyState } from "@/components/EmptyState"
import { useAppModal } from "@/components/AppModalProvider"
import { api } from "@/services/api"
import type { Subject, SubjectBundle } from "@/types"
import { format } from "date-fns"

export function SubjectsPage() {
  const navigate = useNavigate()
  const { showError } = useAppModal()
  const [tab, setTab] = useState("subjects")
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [bundles, setBundles] = useState<SubjectBundle[]>([])
  const [loading, setLoading] = useState(true)

  // Subject form
  const [subjectDialog, setSubjectDialog] = useState(false)
  const [editingSubject, setEditingSubject] = useState<Subject | null>(null)
  const [subjectForm, setSubjectForm] = useState({ title: "", description: "", category: "" })
  const [saving, setSaving] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<{ type: "subject" | "bundle"; id: string; name: string } | null>(null)

  // Bundle form
  const [bundleDialog, setBundleDialog] = useState(false)
  const [editingBundle, setEditingBundle] = useState<SubjectBundle | null>(null)
  const [bundleForm, setBundleForm] = useState({ name: "", subjectIds: [] as string[] })

  const fetchData = useCallback(async () => {
    setLoading(true)
    try {
      const [subRes, bunRes] = await Promise.all([
        api.getSubjects({ limit: 100 }),
        api.getBundles(),
      ])
      setSubjects(subRes.data)
      setBundles(bunRes)
    } catch {
      //
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  // ── Subject CRUD ──
  const openSubjectForm = (subject?: Subject) => {
    if (subject) {
      setEditingSubject(subject)
      setSubjectForm({ title: subject.title, description: subject.description || "", category: subject.category })
    } else {
      setEditingSubject(null)
      setSubjectForm({ title: "", description: "", category: "" })
    }
    setSubjectDialog(true)
  }

  const saveSubject = async () => {
    setSaving(true)
    try {
      if (editingSubject) {
        await api.updateSubject(editingSubject._id, subjectForm)
      } else {
        await api.createSubject(subjectForm)
      }
      setSubjectDialog(false)
      fetchData()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Failed to save subject")
    } finally {
      setSaving(false)
    }
  }

  // ── Bundle CRUD ──
  const openBundleForm = (bundle?: SubjectBundle) => {
    if (bundle) {
      setEditingBundle(bundle)
      setBundleForm({
        name: bundle.name,
        subjectIds: (bundle.subjects as Subject[]).map((s) => (typeof s === "string" ? s : s._id)),
      })
    } else {
      setEditingBundle(null)
      setBundleForm({ name: "", subjectIds: [] })
    }
    setBundleDialog(true)
  }

  const saveBundle = async () => {
    setSaving(true)
    try {
      if (editingBundle) {
        await api.updateBundle(editingBundle._id, bundleForm)
      } else {
        await api.createBundle(bundleForm)
      }
      setBundleDialog(false)
      fetchData()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Failed to save bundle")
    } finally {
      setSaving(false)
    }
  }

  // ── Delete ──
  const handleDelete = async () => {
    if (!deleteTarget) return
    try {
      if (deleteTarget.type === "subject") await api.deleteSubject(deleteTarget.id)
      else await api.deleteBundle(deleteTarget.id)
      setDeleteTarget(null)
      fetchData()
    } catch (err) {
      showError(err instanceof Error ? err.message : "Delete failed")
    }
  }

  if (loading) return <LoadingState />

  return (
    <div className="space-y-4">
      <Tabs value={tab} onValueChange={setTab}>
        <div className="flex items-center justify-between">
          <TabsList>
            <TabsTrigger value="subjects">Subjects</TabsTrigger>
            <TabsTrigger value="bundles">Bundles</TabsTrigger>
          </TabsList>
          <Button
            size="sm"
            onClick={() => (tab === "subjects" ? openSubjectForm() : openBundleForm())}
          >
            <Plus className="mr-2 h-4 w-4" />
            {tab === "subjects" ? "New Subject" : "New Bundle"}
          </Button>
        </div>

        {/* Subjects Tab */}
        <TabsContent value="subjects">
          {subjects.length === 0 ? (
            <EmptyState title="No subjects" description="Create your first subject to get started." />
          ) : (
            <div className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Title</TableHead>
                    <TableHead>Category</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Created</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {subjects.map((s) => (
                    <TableRow
                      key={s._id}
                      className="cursor-pointer hover:bg-muted/50"
                      onClick={() => navigate(`/subjects/${s._id}`)}
                    >
                      <TableCell className="font-medium">
                        <div className="flex items-center gap-2">
                          {s.title}
                          <ChevronRight className="h-4 w-4 text-muted-foreground" />
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{s.category}</Badge>
                      </TableCell>
                      <TableCell>
                        {s.isActive ? (
                          <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">Active</Badge>
                        ) : (
                          <Badge variant="secondary">Inactive</Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {format(new Date(s.createdAt), "MMM d, yyyy")}
                      </TableCell>
                      <TableCell className="text-right">
                        <div
                          className="flex items-center justify-end gap-1"
                          onClick={(e) => e.stopPropagation()}
                        >
                          <Button variant="ghost" size="sm" onClick={() => openSubjectForm(s)} title="Edit">
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setDeleteTarget({ type: "subject", id: s._id, name: s.title })}
                            title="Delete"
                          >
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
        </TabsContent>

        {/* Bundles Tab */}
        <TabsContent value="bundles">
          {bundles.length === 0 ? (
            <EmptyState title="No bundles" description="Create a bundle to group subjects together." />
          ) : (
            <div className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Subjects</TableHead>
                    <TableHead>Created</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {bundles.map((b) => (
                    <TableRow key={b._id}>
                      <TableCell className="font-medium">{b.name}</TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-1">
                          {(b.subjects as Subject[]).map((s) => (
                            <Badge key={typeof s === "string" ? s : s._id} variant="outline" className="text-xs">
                              {typeof s === "string" ? s : s.title}
                            </Badge>
                          ))}
                        </div>
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {format(new Date(b.createdAt), "MMM d, yyyy")}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex items-center justify-end gap-1">
                          <Button variant="ghost" size="sm" onClick={() => openBundleForm(b)}>
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setDeleteTarget({ type: "bundle", id: b._id, name: b.name })}
                          >
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
        </TabsContent>
      </Tabs>

      {/* Subject Dialog */}
      <Dialog open={subjectDialog} onOpenChange={setSubjectDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingSubject ? "Edit Subject" : "New Subject"}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Title</Label>
              <Input value={subjectForm.title} onChange={(e) => setSubjectForm((f) => ({ ...f, title: e.target.value }))} />
            </div>
            <div className="space-y-2">
              <Label>Category</Label>
              <Input
                value={subjectForm.category}
                onChange={(e) => setSubjectForm((f) => ({ ...f, category: e.target.value }))}
                placeholder="e.g. Mathematics, Physics"
              />
            </div>
            <div className="space-y-2">
              <Label>Description</Label>
              <Textarea
                value={subjectForm.description}
                onChange={(e) => setSubjectForm((f) => ({ ...f, description: e.target.value }))}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setSubjectDialog(false)}>Cancel</Button>
            <Button onClick={saveSubject} disabled={saving || !subjectForm.title || !subjectForm.category}>
              {saving ? <RotateCw className="mr-2 h-4 w-4 animate-spin" /> : null}
              {editingSubject ? "Update" : "Create"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Bundle Dialog */}
      <Dialog open={bundleDialog} onOpenChange={setBundleDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingBundle ? "Edit Bundle" : "New Bundle"}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Bundle Name</Label>
              <Input value={bundleForm.name} onChange={(e) => setBundleForm((f) => ({ ...f, name: e.target.value }))} />
            </div>
            <div className="space-y-2">
              <Label>Select Subjects</Label>
              <div className="grid grid-cols-1 gap-2 max-h-48 overflow-auto rounded-md border p-3">
                {subjects.map((s) => (
                  <label key={s._id} className="flex items-center gap-2 text-sm cursor-pointer">
                    <input
                      type="checkbox"
                      checked={bundleForm.subjectIds.includes(s._id)}
                      onChange={(e) => {
                        setBundleForm((f) => ({
                          ...f,
                          subjectIds: e.target.checked
                            ? [...f.subjectIds, s._id]
                            : f.subjectIds.filter((id) => id !== s._id),
                        }))
                      }}
                      className="rounded"
                    />
                    {s.title}
                  </label>
                ))}
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setBundleDialog(false)}>Cancel</Button>
            <Button onClick={saveBundle} disabled={saving || !bundleForm.name || bundleForm.subjectIds.length === 0}>
              {saving ? <RotateCw className="mr-2 h-4 w-4 animate-spin" /> : null}
              {editingBundle ? "Update" : "Create"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteTarget} onOpenChange={() => setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete {deleteTarget?.name}?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone.
            </AlertDialogDescription>
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
