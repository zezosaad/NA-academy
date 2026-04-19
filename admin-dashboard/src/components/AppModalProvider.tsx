import { createContext, useCallback, useContext, useMemo, useState } from "react"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"

type AppModalVariant = "info" | "success" | "error"

interface AppModalOptions {
  title?: string
  message: string
  variant?: AppModalVariant
}

interface AppModalContextValue {
  showModal: (options: AppModalOptions) => void
  showError: (message: string, title?: string) => void
  showSuccess: (message: string, title?: string) => void
  showInfo: (message: string, title?: string) => void
}

const AppModalContext = createContext<AppModalContextValue | null>(null)

const getDefaultTitle = (variant: AppModalVariant): string => {
  switch (variant) {
    case "success":
      return "Success"
    case "error":
      return "Error"
    default:
      return "Notice"
  }
}

export function AppModalProvider({ children }: { children: React.ReactNode }) {
  const [open, setOpen] = useState(false)
  const [options, setOptions] = useState<AppModalOptions | null>(null)

  const showModal = useCallback((next: AppModalOptions) => {
    setOptions(next)
    setOpen(true)
  }, [])

  const showError = useCallback((message: string, title?: string) => {
    showModal({ message, title, variant: "error" })
  }, [showModal])

  const showSuccess = useCallback((message: string, title?: string) => {
    showModal({ message, title, variant: "success" })
  }, [showModal])

  const showInfo = useCallback((message: string, title?: string) => {
    showModal({ message, title, variant: "info" })
  }, [showModal])

  const value = useMemo(
    () => ({ showModal, showError, showSuccess, showInfo }),
    [showModal, showError, showSuccess, showInfo]
  )

  const variant: AppModalVariant = options?.variant || "info"

  return (
    <AppModalContext.Provider value={value}>
      {children}
      <AlertDialog open={open} onOpenChange={setOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{options?.title || getDefaultTitle(variant)}</AlertDialogTitle>
            <AlertDialogDescription>{options?.message}</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogAction>OK</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AppModalContext.Provider>
  )
}

export function useAppModal() {
  const context = useContext(AppModalContext)
  if (!context) {
    throw new Error("useAppModal must be used within AppModalProvider")
  }
  return context
}
