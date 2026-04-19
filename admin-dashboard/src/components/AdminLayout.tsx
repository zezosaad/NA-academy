import { useState } from "react"
import { Link, useLocation } from "react-router-dom"
import {
  LayoutDashboard,
  Users,
  BookOpen,
  FileQuestion,
  KeyRound,
  ShieldAlert,
  LogOut,
  Menu,
  X,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Separator } from "@/components/ui/separator"
import { cn } from "@/lib/utils"
import { clearToken } from "@/lib/auth"

const NAV_ITEMS = [
  { label: "Dashboard", href: "/", icon: LayoutDashboard },
  { label: "Users", href: "/users", icon: Users },
  { label: "Subjects", href: "/subjects", icon: BookOpen },
  { label: "Exams", href: "/exams", icon: FileQuestion },
  { label: "Activation Codes", href: "/codes", icon: KeyRound },
  { label: "Security", href: "/security", icon: ShieldAlert },
]

interface AdminLayoutProps {
  children: React.ReactNode
  adminName?: string
}

export function AdminLayout({ children, adminName = "Admin" }: AdminLayoutProps) {
  const location = useLocation()
  const [sidebarOpen, setSidebarOpen] = useState(false)

  const handleLogout = () => {
    clearToken()
    window.location.reload()
  }

  return (
    <div className="flex h-screen overflow-hidden bg-background">
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 flex w-64 flex-col border-r bg-card transition-transform duration-200 lg:static lg:translate-x-0",
          sidebarOpen ? "translate-x-0" : "-translate-x-full"
        )}
      >
        <div className="flex h-14 items-center gap-2 border-b px-4">
          <div className="flex h-8 w-8 items-center justify-center rounded-md bg-primary text-primary-foreground text-sm font-bold">
            NA
          </div>
          <span className="font-semibold tracking-tight">NA Academy</span>
          <Button
            variant="ghost"
            size="sm"
            className="ml-auto lg:hidden"
            onClick={() => setSidebarOpen(false)}
          >
            <X className="h-4 w-4" />
          </Button>
        </div>

        <ScrollArea className="flex-1 px-3 py-4">
          <nav className="flex flex-col gap-1">
            {NAV_ITEMS.map((item) => {
              const isActive =
                item.href === "/"
                  ? location.pathname === "/"
                  : location.pathname.startsWith(item.href)
              return (
                <Link
                  key={item.href}
                  to={item.href}
                  onClick={() => setSidebarOpen(false)}
                  className={cn(
                    "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
                    isActive
                      ? "bg-primary text-primary-foreground"
                      : "text-muted-foreground hover:bg-muted hover:text-foreground"
                  )}
                >
                  <item.icon className="h-4 w-4" />
                  {item.label}
                </Link>
              )
            })}
          </nav>
        </ScrollArea>

        <Separator />
        <div className="p-3">
          <div className="flex items-center gap-3 rounded-md px-3 py-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-muted text-xs font-bold uppercase">
              {adminName.charAt(0)}
            </div>
            <div className="flex-1 truncate">
              <p className="text-sm font-medium truncate">{adminName}</p>
              <p className="text-xs text-muted-foreground">Administrator</p>
            </div>
            <Button variant="ghost" size="sm" onClick={handleLogout} title="Logout">
              <LogOut className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex flex-1 flex-col overflow-hidden">
        {/* Top bar */}
        <header className="flex h-14 items-center gap-4 border-b bg-card px-4 lg:px-6">
          <Button
            variant="ghost"
            size="sm"
            className="lg:hidden"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="h-5 w-5" />
          </Button>
          <h2 className="text-lg font-semibold">
            {NAV_ITEMS.find(
              (i) =>
                i.href === "/"
                  ? location.pathname === "/"
                  : location.pathname.startsWith(i.href)
            )?.label ?? "Dashboard"}
          </h2>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-auto p-4 lg:p-6">{children}</main>
      </div>
    </div>
  )
}
