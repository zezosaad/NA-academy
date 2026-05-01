import { useState } from 'react'
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
import { sendNotification } from '@/services/notifications.api'
import type { AudienceDto, NotificationResponseDto } from '@/types/notifications'

const schema = z
  .object({
    title: z.string().min(1, 'Title is required').max(100, 'Title must be ≤100 characters'),
    body: z.string().min(1, 'Message body is required').max(1000, 'Body must be ≤1000 characters'),
    data: z
      .string()
      .optional()
      .refine((val) => {
        if (!val || val.trim() === '') return true
        try {
          const parsed = JSON.parse(val)
          return (
            typeof parsed === 'object' &&
            parsed !== null &&
            !Array.isArray(parsed) &&
            Object.values(parsed).every((v) => typeof v === 'string')
          )
        } catch {
          return false
        }
      }, { message: 'Data must be valid JSON with string values only, e.g. {"key": "value"}' }),
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

interface NotificationComposerProps {
  onSent?: (notification: NotificationResponseDto) => void
}

export function NotificationComposer({ onSent }: NotificationComposerProps) {
  const role = useCurrentUserRole()
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle')
  const [errorMessage, setErrorMessage] = useState('')
  const [lastSentId, setLastSentId] = useState<string | null>(null)

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

  const onSubmit = async (values: FormValues) => {
    setStatus('loading')
    setErrorMessage('')

    try {
      let data: Record<string, string> | undefined
      if (values.data && values.data.trim()) {
        data = JSON.parse(values.data) as Record<string, string>
      }

      const result = await sendNotification({
        title: values.title,
        body: values.body,
        data,
        audience: values.audience,
      })

      setStatus('success')
      setLastSentId(result.id)
      onSent?.(result)
      reset({
        title: '',
        body: '',
        data: '',
        audience: role === 'teacher' ? { kind: 'subject' } : { kind: 'all' },
      })
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
            <Label htmlFor="data" className="text-sm font-medium text-stone-700">
              Payload <span className="font-normal text-stone-400">(optional JSON)</span>
            </Label>
            <Textarea
              id="data"
              placeholder='{"type": "lesson", "lessonId": "..."}'
              rows={3}
              className="resize-none border-stone-200 bg-white font-mono text-xs focus-visible:ring-teal-600"
              {...register('data')}
            />
            {errors.data && <p className="text-xs text-red-600">{errors.data.message}</p>}
          </div>

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
