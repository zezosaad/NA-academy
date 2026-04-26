import { useState, useEffect } from "react"
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom"
import "./index.css"
import { Dashboard } from "./components/Dashboard"
import { LoginPage } from "./components/LoginPage"
import { AdminLayout } from "./components/AdminLayout"
import { UsersPage } from "./pages/UsersPage"
import { SubjectsPage } from "./pages/SubjectsPage"
import { SubjectDetailPage } from "./pages/SubjectDetailPage"
import { ExamsPage } from "./pages/ExamsPage"
import { CodesPage } from "./pages/CodesPage"
import { SecurityPage } from "./pages/SecurityPage"
import { isAuthenticated } from "@/lib/auth"
import { AppModalProvider } from "@/components/AppModalProvider"

function ProtectedRoute({ children, onAuthExpired }: { children: React.ReactNode; onAuthExpired: () => void }) {
  const authed = isAuthenticated()
  useEffect(() => {
    if (!authed) onAuthExpired()
  }, [authed, onAuthExpired])
  if (!authed) {
    return <Navigate to="/login" replace />
  }
  return <>{children}</>
}

function App() {
  const [authed, setAuthed] = useState(isAuthenticated())

  return (
    <AppModalProvider>
      <BrowserRouter>
        <Routes>
          <Route
            path="/login"
            element={
              authed ? <Navigate to="/" replace /> : <LoginPage onLogin={() => setAuthed(true)} />
            }
          />
          <Route
            path="/*"
            element={
              <ProtectedRoute onAuthExpired={() => setAuthed(false)}>
                <AdminLayout>
                  <Routes>
                    <Route path="/" element={<Dashboard />} />
                    <Route path="/users" element={<UsersPage />} />
                    <Route path="/subjects" element={<SubjectsPage />} />
                    <Route path="/subjects/:id" element={<SubjectDetailPage />} />
                    <Route path="/exams" element={<ExamsPage />} />
                    <Route path="/codes" element={<CodesPage />} />
                    <Route path="/security" element={<SecurityPage />} />
                    <Route path="*" element={<Navigate to="/" replace />} />
                  </Routes>
                </AdminLayout>
              </ProtectedRoute>
            }
          />
        </Routes>
      </BrowserRouter>
    </AppModalProvider>
  )
}

export default App
