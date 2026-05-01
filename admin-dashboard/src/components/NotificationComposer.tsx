import { useEffect, useMemo, useState } from 'react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { Bell, Send, Loader2, CheckCircle2, AlertCircle } from 'lucide-react'

import { AudiencePicker } from '@/components/AudiencePicker'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { useCurrentUserRole } from '@/hooks/useCurrentUserRole'
import { api } from '@/services/api'
import {
  getAllExams,
  getAllSubjects,
  getTeachingSubjects,
  sendNotification,
} from '@/services/notifications.api'
import type { Lesson } from '@/types'
import type {
  AudienceDto,
  AudienceSubjectOption,
  NotificationResponseDto,
} from '@/types/notifications'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

const schema = z
  .object({
    title: z.string().min(1, 'Title is required').max(100, 'Title must be ≤100 characters'),
    body: z.string().min(1, 'Message body is required').max(1000, 'Body must be ≤1000 characters'),
    audience: z.object({
      kind: z.enum(['all', 'user-list', 'subject']),
      userIds: z.array(z.string()).optional(),
      subjectId: z.string().optional(),
    }),
  })
  .superRefine((values, ctx) => {
    if (values.audience.kind === 'user-list' && (!values.audience.userIds || values.audience.userIds.length === 0)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['audience', 'userIds'],
        message: 'Select at least one user',
      })
    }

    if (values.audience.kind === 'subject' && !values.audience.subjectId) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['audience', 'subjectId'],
        message: 'Select a subject',
      })
    }
  })

type FormValues = z.infer<typeof schema>
type PayloadType = 'none' | 'subject' | 'lesson' | 'exam' | 'url'

interface NotificationComposerProps {
  onSent?: (notification: NotificationResponseDto) => void
}

export function NotificationComposer({ onSent }: NotificationComposerProps) {
  const role = useCurrentUserRole()
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle')
  const [errorMessage, setErrorMessage] = useState('')
  const [lastSentId, setLastSentId] = useState<string | null>(null)
  const [payloadType, setPayloadType] = useState<PayloadType>('none')
  const [payloadSubjectId, setPayloadSubjectId] = useState('')
  const [payloadLessonSubjectId, setPayloadLessonSubjectId] = useState('')
  const [payloadLessonId, setPayloadLessonId] = useState('')
  const [payloadExamId, setPayloadExamId] = useState('')
  const [payloadUrl, setPayloadUrl] = useState('')
  const [payloadError, setPayloadError] = useState<string | null>(null)
  const [payloadTargetsError, setPayloadTargetsError] = useState<string | null>(null)
  const [payloadSubjects, setPayloadSubjects] = useState<AudienceSubjectOption[]>([])
  const [payloadLessons, setPayloadLessons] = useState<Lesson[]>([])
  const [payloadExams, setPayloadExams] = useState<Array<{ _id: string; title: string; subjectId: string | { _id: string; title: string } }>>([])
  const [payloadLoading, setPayloadLoading] = useState(false)

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      audience: role === 'teacher' ? { kind: 'subject' } : { kind: 'all' },
    },
  })

  const bodyValue = watch('body') ?? ''
  const audience = watch('audience') as AudienceDto

  const selectedExam = useMemo(
    () => payloadExams.find((exam) => exam._id === payloadExamId) ?? null,
    [payloadExamId, payloadExams],
  )

  useEffect(() => {
    const loadPayloadTargets = async () => {
      setPayloadLoading(true)
      setPayloadTargetsError(null)

      const [subjectsResult, examsResult] = await Promise.allSettled([
        role === 'teacher' ? getTeachingSubjects() : getAllSubjects(),
        getAllExams(),
      ])

      if (subjectsResult.status === 'fulfilled') {
        setPayloadSubjects(subjectsResult.value)
      } else {
        console.error('Failed to load payload subjects', subjectsResult.reason)
        setPayloadSubjects([])
        setPayloadTargetsError('Unable to load subjects list')
      }

      if (examsResult.status === 'fulfilled') {
        setPayloadExams(examsResult.value)
      } else {
        console.error('Failed to load payload exams', examsResult.reason)
        setPayloadExams([])
      }

      setPayloadLoading(false)
    }

    void loadPayloadTargets()
  }, [role])

  useEffect(() => {
    if (payloadType !== 'lesson' || !payloadLessonSubjectId) {
      setPayloadLessons([])
      setPayloadLessonId('')
      return
    }

    const loadLessons = async () => {
      try {
        const lessons = await api.getLessons(payloadLessonSubjectId)
        setPayloadLessons(lessons)
      } catch (error) {
        console.error('Failed to load lessons for payload', error)
        setPayloadLessons([])
      }
    }

    void loadLessons()
  }, [payloadLessonSubjectId, payloadType])

  const onSubmit = async (values: FormValues) => {
    setStatus('loading')
    setErrorMessage('')
    setPayloadError(null)

    try {
      let data: Record<string, string> = {}

      if (payloadType === 'subject') {
        if (!payloadSubjectId) {
          setPayloadError('Please select a subject for payload')
          setStatus('idle')
          return
        }
        data = { ...data, type: 'subject', id: payloadSubjectId }
      }

      if (payloadType === 'lesson') {
        if (!payloadLessonSubjectId || !payloadLessonId) {
          setPayloadError('Please select subject and lesson for payload')
          setStatus('idle')
          return
        }
        data = {
          ...data,
          type: 'lesson',
          subjectId: payloadLessonSubjectId,
          id: payloadLessonId,
        }
      }

      if (payloadType === 'exam') {
        if (!payloadExamId) {
          setPayloadError('Please select an exam for payload')
          setStatus('idle')
          return
        }
        data = { ...data, type: 'exam', id: payloadExamId }
      }

      if (payloadType === 'url') {
        const normalizedUrl = payloadUrl.trim()
        if (!normalizedUrl) {
          setPayloadError('Please enter URL for payload')
          setStatus('idle')
          return
        }

        try {
          // Validate URL format before sending.
          // eslint-disable-next-line no-new
          new URL(normalizedUrl)
        } catch {
          setPayloadError('Please enter a valid URL (https://...)')
          setStatus('idle')
          return
        }

        data = { ...data, type: 'url', url: normalizedUrl }
      }

      const finalData = Object.keys(data).length > 0 ? data : undefined

      const result = await sendNotification({
        title: values.title,
        body: values.body,
        data: finalData,
        audience: values.audience,
      })

      setStatus('success')
      setLastSentId(result.id)
      onSent?.(result)
      reset({
        title: '',
        body: '',
        audience: role === 'teacher' ? { kind: 'subject' } : { kind: 'all' },
      })
      setPayloadType('none')
      setPayloadSubjectId('')
      setPayloadLessonSubjectId('')
      setPayloadLessonId('')
      setPayloadExamId('')
      setPayloadUrl('')
    } catch (err) {
      setStatus('error')
      setErrorMessage(err instanceof Error ? err.message : 'Failed to send notification')
    }
  }

  return (
    <Card className="mx-auto max-w-2xl border-stone-200 bg-[#FAF7F2] shadow-sm">
      <CardHeader className="border-b border-stone-100 pb-4">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-teal-600/10">
            <Bell className="h-5 w-5 text-teal-700" />
          </div>
          <div>
            <CardTitle className="font-[Fraunces] text-lg text-stone-900">Compose Notification</CardTitle>
            <CardDescription className="text-sm text-stone-500">
              Choose an audience and deliver a targeted push notification.
            </CardDescription>
          </div>
        </div>
      </CardHeader>

      <CardContent className="pt-6">
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
          <div className="space-y-1.5">
            <Label htmlFor="title" className="text-sm font-medium text-stone-700">Title</Label>
            <Input
              id="title"
              placeholder="e.g. New Lesson Available"
              className="border-stone-200 bg-white focus-visible:ring-teal-600"
              {...register('title')}
            />
            {errors.title && <p className="text-xs text-red-600">{errors.title.message}</p>}
          </div>

          <div className="space-y-1.5">
            <div className="flex items-baseline justify-between">
              <Label htmlFor="body" className="text-sm font-medium text-stone-700">Message</Label>
              <span className="text-xs text-stone-400">{bodyValue.length}/1000</span>
            </div>
            <Textarea
              id="body"
              placeholder="Write your notification message here..."
              rows={4}
              className="resize-none border-stone-200 bg-white focus-visible:ring-teal-600"
              {...register('body')}
            />
            {errors.body && <p className="text-xs text-red-600">{errors.body.message}</p>}
          </div>

          <div className="space-y-1.5">
            <Label className="text-sm font-medium text-stone-700">Payload target</Label>
            <Select
              value={payloadType}
              onValueChange={(value) => {
                setPayloadType(value as PayloadType)
                setPayloadError(null)
              }}
            >
              <SelectTrigger className="border-stone-200 bg-white focus:ring-teal-600">
                <SelectValue placeholder="Choose target type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="none">None</SelectItem>
                <SelectItem value="subject">Open subject</SelectItem>
                <SelectItem value="lesson">Open lesson</SelectItem>
                <SelectItem value="exam">Open exam</SelectItem>
                <SelectItem value="url">Open URL</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {payloadType === 'subject' && (
            <div className="space-y-1.5">
              <Label className="text-sm font-medium text-stone-700">Choose subject</Label>
              <Select value={payloadSubjectId} onValueChange={setPayloadSubjectId}>
                <SelectTrigger className="border-stone-200 bg-white focus:ring-teal-600">
                  <SelectValue placeholder={payloadLoading ? 'Loading subjects...' : 'Select subject'} />
                </SelectTrigger>
                <SelectContent>
                  {payloadSubjects.map((subject) => (
                    <SelectItem key={subject.id} value={subject.id}>
                      {subject.title}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {payloadTargetsError && <p className="text-xs text-red-600">{payloadTargetsError}</p>}
              {!payloadLoading && !payloadTargetsError && payloadSubjects.length === 0 && (
                <p className="text-xs text-stone-500">No subjects available for your account.</p>
              )}
            </div>
          )}

          {payloadType === 'lesson' && (
            <div className="grid gap-3 md:grid-cols-2">
              <div className="space-y-1.5">
                <Label className="text-sm font-medium text-stone-700">Choose subject</Label>
                <Select
                  value={payloadLessonSubjectId}
                  onValueChange={(nextSubjectId) => {
                    setPayloadLessonSubjectId(nextSubjectId)
                    setPayloadLessonId('')
                  }}
                >
                  <SelectTrigger className="border-stone-200 bg-white focus:ring-teal-600">
                    <SelectValue placeholder={payloadLoading ? 'Loading subjects...' : 'Select subject'} />
                  </SelectTrigger>
                  <SelectContent>
                    {payloadSubjects.map((subject) => (
                      <SelectItem key={subject.id} value={subject.id}>
                        {subject.title}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-1.5">
                <Label className="text-sm font-medium text-stone-700">Choose lesson</Label>
                <Select
                  value={payloadLessonId}
                  onValueChange={setPayloadLessonId}
                  disabled={!payloadLessonSubjectId}
                >
                  <SelectTrigger className="border-stone-200 bg-white focus:ring-teal-600">
                    <SelectValue
                      placeholder={
                        !payloadLessonSubjectId
                          ? 'Select subject first'
                          : payloadLessons.length === 0
                            ? 'No lessons found'
                            : 'Select lesson'
                      }
                    />
                  </SelectTrigger>
                  <SelectContent>
                    {payloadLessons.map((lesson) => (
                      <SelectItem key={lesson._id} value={lesson._id}>
                        {lesson.title}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
          )}

          {payloadType === 'exam' && (
            <div className="space-y-1.5">
              <Label className="text-sm font-medium text-stone-700">Choose exam</Label>
              <Select value={payloadExamId} onValueChange={setPayloadExamId}>
                <SelectTrigger className="border-stone-200 bg-white focus:ring-teal-600">
                  <SelectValue placeholder={payloadLoading ? 'Loading exams...' : 'Select exam'} />
                </SelectTrigger>
                <SelectContent>
                  {payloadExams.map((exam) => (
                    <SelectItem key={exam._id} value={exam._id}>
                      {exam.title}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {selectedExam && (
                <p className="text-xs text-stone-500">
                  Linked subject:{' '}
                  {typeof selectedExam.subjectId === 'string'
                    ? payloadSubjects.find((subject) => subject.id === selectedExam.subjectId)?.title ?? selectedExam.subjectId
                    : selectedExam.subjectId.title}
                </p>
              )}
            </div>
          )}

          {payloadType === 'url' && (
            <div className="space-y-1.5">
              <Label htmlFor="payload-url" className="text-sm font-medium text-stone-700">Destination URL</Label>
              <Input
                id="payload-url"
                value={payloadUrl}
                onChange={(event) => setPayloadUrl(event.target.value)}
                placeholder="https://example.com/path"
                className="border-stone-200 bg-white focus-visible:ring-teal-600"
              />
            </div>
          )}

          {payloadError && <p className="text-xs text-red-600">{payloadError}</p>}

          <AudiencePicker
            value={audience}
            role={role}
            onChange={(nextAudience) => {
              setValue('audience', nextAudience, { shouldDirty: true, shouldValidate: true })
            }}
          />
          {errors.audience?.userIds && <p className="text-xs text-red-600">{errors.audience.userIds.message}</p>}
          {errors.audience?.subjectId && <p className="text-xs text-red-600">{errors.audience.subjectId.message}</p>}

          {status === 'success' && (
            <div className="flex items-center gap-2 rounded-lg border border-green-100 bg-green-50 px-3 py-2.5 text-sm text-green-700">
              <CheckCircle2 className="h-4 w-4 flex-shrink-0" />
              <span>
                Notification sent successfully!{' '}
                {lastSentId && <span className="font-mono text-xs text-green-600">#{lastSentId.slice(-8)}</span>}
              </span>
            </div>
          )}

          {status === 'error' && (
            <div className="flex items-center gap-2 rounded-lg border border-red-100 bg-red-50 px-3 py-2.5 text-sm text-red-700">
              <AlertCircle className="h-4 w-4 flex-shrink-0" />
              <span>{errorMessage}</span>
            </div>
          )}

          <Button
            type="submit"
            disabled={status === 'loading'}
            className="w-full rounded-full bg-teal-700 py-2.5 text-sm font-medium text-white hover:bg-teal-800 disabled:opacity-60"
          >
            {status === 'loading' ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Sending...
              </>
            ) : (
              <>
                <Send className="mr-2 h-4 w-4" />
                Send Notification
              </>
            )}
          </Button>
        </form>
      </CardContent>
    </Card>
  )
}
