import { useState, useEffect, useRef, useCallback } from "react"
import { io, Socket } from "socket.io-client"
import { Send, MessageCircle, Circle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { LoadingState } from "@/components/LoadingState"
import { EmptyState } from "@/components/EmptyState"
import { cn } from "@/lib/utils"
import { api } from "@/services/api"
import type { ChatConversationPreview, ChatMessage } from "@/types"
import { format, isToday, isYesterday } from "date-fns"

const API_URL = import.meta.env.VITE_API_URL ?? ""

function normalizeApiBaseForMedia(rawBase: string): string {
  const trimmed = rawBase.trim().replace(/\/+$/, "")
  if (trimmed.endsWith("/api/v1")) return trimmed
  if (trimmed.endsWith("/api")) return `${trimmed}/v1`
  return `${trimmed}/api/v1`
}

function mediaStreamUrl(imageFileId: string): string {
  return `${normalizeApiBaseForMedia(API_URL)}/media/${imageFileId}/stream`
}

function formatMsgTime(dateStr: string): string {
  const d = new Date(dateStr)
  if (isToday(d)) return format(d, "HH:mm")
  if (isYesterday(d)) return `Yesterday ${format(d, "HH:mm")}`
  return format(d, "dd MMM HH:mm")
}

function getSenderName(msg: ChatMessage): string {
  if (typeof msg.senderId === "object" && msg.senderId !== null) {
    return (msg.senderId as { name: string }).name
  }
  return ""
}

function getSenderId(msg: ChatMessage): string {
  if (typeof msg.senderId === "object" && msg.senderId !== null) {
    return (msg.senderId as { _id: string })._id
  }
  return msg.senderId as string
}

export function ChatPage() {
  const [conversations, setConversations] = useState<ChatConversationPreview[]>([])
  const [loadingConvs, setLoadingConvs] = useState(true)
  const [selectedConv, setSelectedConv] = useState<ChatConversationPreview | null>(null)
  const [messages, setMessages] = useState<Map<string, ChatMessage[]>>(new Map())
  const [loadingMsgs, setLoadingMsgs] = useState(false)
  const [text, setText] = useState("")
  const [isConnected, setIsConnected] = useState(false)
  const [typingUsers, setTypingUsers] = useState<Set<string>>(new Set())
  const socketRef = useRef<Socket | null>(null)
  const bottomRef = useRef<HTMLDivElement>(null)
  const typingTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  // admin user id decoded from token for own-message detection
  const adminIdRef = useRef<string>("")
  const authToken = api.getSocketToken() ?? ""

  // Decode admin id from JWT (payload.sub)
  useEffect(() => {
    const token = api.getSocketToken()
    if (!token) return
    try {
      const payload = JSON.parse(atob(token.split(".")[1]))
      adminIdRef.current = payload.sub ?? payload.userId ?? ""
    } catch {
      //
    }
  }, [])

  // Connect Socket
  useEffect(() => {
    const token = api.getSocketToken()
    if (!token) return

    const socket = io(`${API_URL}/chat`, {
      auth: { token },
      transports: ["websocket"],
    })
    socketRef.current = socket

    socket.on("connect", () => setIsConnected(true))
    socket.on("disconnect", () => setIsConnected(false))

    socket.on("new_message", (msg: ChatMessage) => {
      setMessages((prev) => {
        const updated = new Map(prev)
        const existing = updated.get(msg.conversationId) ?? []
        // Deduplicate
        if (existing.some((m) => m._id === msg._id)) return prev
        updated.set(msg.conversationId, [...existing, msg])
        return updated
      })
      // Send delivery ack
      socket.emit("delivery_ack", {
        messageId: msg._id,
        senderId: getSenderId(msg),
      })
      // Update unread count in conversation list
      setConversations((prev) =>
        prev.map((c) =>
          c.id === msg.conversationId
            ? {
                ...c,
                unreadCount: c.id === selectedConvRef.current?.id ? 0 : c.unreadCount + 1,
                lastMessage: {
                  text: msg.text,
                  hasImage: msg.messageType === "image",
                  sentAt: msg.createdAt,
                  senderId: getSenderId(msg),
                  status: msg.status,
                },
              }
            : c
        )
      )
    })

    socket.on("pending_messages", (pending: ChatMessage[]) => {
      setMessages((prev) => {
        const updated = new Map(prev)
        for (const msg of pending) {
          const existing = updated.get(msg.conversationId) ?? []
          if (!existing.some((m) => m._id === msg._id)) {
            updated.set(msg.conversationId, [...existing, msg])
          }
        }
        return updated
      })
    })

    socket.on(
      "status_update",
      (data: { messageId: string; status: ChatMessage["status"] }) => {
        setMessages((prev) => {
          const updated = new Map(prev)
          for (const [convId, msgs] of updated) {
            const idx = msgs.findIndex((m) => m._id === data.messageId)
            if (idx >= 0) {
              const copy = [...msgs]
              copy[idx] = { ...copy[idx], status: data.status }
              updated.set(convId, copy)
              break
            }
          }
          return updated
        })
      }
    )

    socket.on("conversation_read", (data: { conversationId: string }) => {
      setMessages((prev) => {
        const updated = new Map(prev)
        const msgs = updated.get(data.conversationId)
        if (msgs) {
          updated.set(
            data.conversationId,
            msgs.map((m) => ({ ...m, status: "read" as const }))
          )
        }
        return updated
      })
    })

    socket.on(
      "typing_indicator",
      (data: { userId: string; isTyping: boolean }) => {
        setTypingUsers((prev) => {
          const next = new Set(prev)
          if (data.isTyping) next.add(data.userId)
          else next.delete(data.userId)
          return next
        })
      }
    )

    return () => {
      socket.disconnect()
      socketRef.current = null
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Keep a ref to selected conv for use inside socket handlers
  const selectedConvRef = useRef<ChatConversationPreview | null>(null)
  useEffect(() => {
    selectedConvRef.current = selectedConv
  }, [selectedConv])

  // Load conversations
  useEffect(() => {
    setLoadingConvs(true)
    api
      .getChatConversations()
      .then((convs) => setConversations(convs))
      .catch(() => {})
      .finally(() => setLoadingConvs(false))
  }, [])

  // Scroll to bottom on new messages
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [messages, selectedConv])

  const selectConversation = useCallback(
    async (conv: ChatConversationPreview) => {
      setSelectedConv(conv)
      // Mark as read in UI immediately
      setConversations((prev) =>
        prev.map((c) => (c.id === conv.id ? { ...c, unreadCount: 0 } : c))
      )
      // Emit mark_read over socket
      socketRef.current?.emit("mark_read", {
        conversationId: conv.id,
        senderId: conv.counterpartyId,
      })
      // Load history if not yet loaded
      if (!messages.has(conv.id) || messages.get(conv.id)!.length === 0) {
        setLoadingMsgs(true)
        try {
          const history = await api.getChatMessages(conv.id)
          setMessages((prev) => {
            const updated = new Map(prev)
            const existing = updated.get(conv.id) ?? []
            const historyIds = new Set(history.map((m) => m._id))
            const socketOnly = existing.filter((m) => !historyIds.has(m._id))
            updated.set(conv.id, [...history, ...socketOnly])
            return updated
          })
        } catch {
          //
        } finally {
          setLoadingMsgs(false)
        }
      }
    },
    [messages]
  )

  const handleSend = () => {
    if (!text.trim() || !selectedConv) return
    socketRef.current?.emit("send_message", {
      recipientId: selectedConv.counterpartyId,
      text: text.trim(),
      messageType: "text",
    })
    setText("")
    if (typingTimeoutRef.current) clearTimeout(typingTimeoutRef.current)
    socketRef.current?.emit("typing", {
      recipientId: selectedConv.counterpartyId,
      isTyping: false,
    })
  }

  const handleTextChange = (value: string) => {
    setText(value)
    if (!selectedConv) return
    socketRef.current?.emit("typing", {
      recipientId: selectedConv.counterpartyId,
      isTyping: true,
    })
    if (typingTimeoutRef.current) clearTimeout(typingTimeoutRef.current)
    typingTimeoutRef.current = setTimeout(() => {
      socketRef.current?.emit("typing", {
        recipientId: selectedConv.counterpartyId,
        isTyping: false,
      })
    }, 2000)
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  const currentMessages = selectedConv ? messages.get(selectedConv.id) ?? [] : []
  const isOtherTyping = selectedConv
    ? typingUsers.has(selectedConv.counterpartyId)
    : false

  return (
    <div className="flex h-[calc(100vh-3.5rem)] overflow-hidden">
      {/* Conversation list */}
      <aside className="w-72 shrink-0 flex flex-col border-r bg-card">
        <div className="flex items-center justify-between px-4 py-3 border-b">
          <div className="flex items-center gap-2">
            <MessageCircle className="h-4 w-4 text-primary" />
            <span className="font-semibold text-sm">Chats</span>
          </div>
          <div className="flex items-center gap-1.5">
            <Circle
              className={cn(
                "h-2.5 w-2.5 fill-current",
                isConnected ? "text-green-500" : "text-muted-foreground"
              )}
            />
            <span className="text-xs text-muted-foreground">
              {isConnected ? "Live" : "Offline"}
            </span>
          </div>
        </div>

        <ScrollArea className="flex-1">
          {loadingConvs ? (
            <LoadingState message="Loading chats..." />
          ) : conversations.length === 0 ? (
            <EmptyState title="No conversations" description="No one has messaged you yet" />
          ) : (
            <ul className="py-1">
              {conversations.map((conv) => (
                <li key={conv.id || conv.counterpartyId}>
                  <button
                    onClick={() => selectConversation(conv)}
                    className={cn(
                      "w-full text-left flex items-start gap-3 px-4 py-3 transition-colors hover:bg-muted",
                      selectedConv?.id === conv.id && "bg-muted"
                    )}
                  >
                    {/* Avatar */}
                    <div className="flex-shrink-0 h-9 w-9 rounded-full bg-primary/10 flex items-center justify-center text-primary font-semibold text-sm">
                      {conv.counterpartyName.charAt(0).toUpperCase()}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span
                          className={cn(
                            "text-sm truncate",
                            conv.unreadCount > 0 ? "font-semibold" : "font-medium"
                          )}
                        >
                          {conv.counterpartyName}
                        </span>
                        {conv.lastMessage && (
                          <span className="text-xs text-muted-foreground ml-1 shrink-0">
                            {formatMsgTime(conv.lastMessage.sentAt)}
                          </span>
                        )}
                      </div>
                      <div className="flex items-center justify-between mt-0.5">
                        <p className="text-xs text-muted-foreground truncate">
                          {conv.lastMessage?.text ?? (conv.virtual ? conv.subjectTitle : "No messages")}
                        </p>
                        {conv.unreadCount > 0 && (
                          <Badge variant="default" className="ml-1 h-4 min-w-4 px-1 text-[10px] shrink-0">
                            {conv.unreadCount}
                          </Badge>
                        )}
                      </div>
                      {conv.subjectTitle && (
                        <p className="text-[11px] text-primary/70 mt-0.5 truncate">{conv.subjectTitle}</p>
                      )}
                    </div>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </ScrollArea>
      </aside>

      {/* Chat area */}
      <div className="flex-1 flex flex-col min-w-0">
        {!selectedConv ? (
          <div className="flex-1 flex items-center justify-center text-muted-foreground">
            <div className="text-center space-y-2">
              <MessageCircle className="h-10 w-10 mx-auto opacity-30" />
              <p className="text-sm">Select a conversation to start chatting</p>
            </div>
          </div>
        ) : (
          <>
            {/* Header */}
            <div className="flex items-center gap-3 px-5 py-3 border-b bg-card shrink-0">
              <div className="h-9 w-9 rounded-full bg-primary/10 flex items-center justify-center text-primary font-semibold text-sm">
                {selectedConv.counterpartyName.charAt(0).toUpperCase()}
              </div>
              <div>
                <p className="font-semibold text-sm">{selectedConv.counterpartyName}</p>
                {selectedConv.subjectTitle && (
                  <p className="text-xs text-muted-foreground">{selectedConv.subjectTitle}</p>
                )}
              </div>
            </div>

            {/* Messages */}
            <ScrollArea className="flex-1 px-4 py-3">
              {loadingMsgs ? (
                <LoadingState message="Loading messages..." />
              ) : currentMessages.length === 0 ? (
                <EmptyState
                  title="No messages yet"
                  description="Send the first message!"
                  className="mt-12"
                />
              ) : (
                <div className="flex flex-col gap-2">
                  {currentMessages.map((msg) => {
                    const isOwn = getSenderId(msg) === adminIdRef.current
                    return (
                      <div
                        key={msg._id}
                        className={cn("flex flex-col max-w-[70%]", isOwn ? "self-end items-end" : "self-start items-start")}
                      >
                        {!isOwn && (
                          <span className="text-[11px] text-muted-foreground mb-0.5 px-1">
                            {getSenderName(msg)}
                          </span>
                        )}
                        <div
                          className={cn(
                            "rounded-2xl px-3.5 py-2 text-sm overflow-hidden",
                            isOwn
                              ? "bg-primary text-primary-foreground rounded-br-sm"
                              : "bg-muted text-foreground rounded-bl-sm"
                          )}
                        >
                          {msg.messageType === "image" && msg.imageFileId && (
                            <ChatImagePreview
                              imageFileId={msg.imageFileId}
                              token={authToken}
                            />
                          )}
                          {msg.text && <div>{msg.text}</div>}
                        </div>
                        <div className="flex items-center gap-1 mt-0.5 px-1">
                          <span className="text-[10px] text-muted-foreground">
                            {formatMsgTime(msg.createdAt)}
                          </span>
                          {isOwn && (
                            <span className="text-[10px] text-muted-foreground">
                              {msg.status === "read" ? "✓✓" : msg.status === "delivered" ? "✓✓" : "✓"}
                            </span>
                          )}
                        </div>
                      </div>
                    )
                  })}
                  {isOtherTyping && (
                    <div className="self-start">
                      <div className="bg-muted rounded-2xl rounded-bl-sm px-3.5 py-2 text-xs text-muted-foreground italic">
                        typing…
                      </div>
                    </div>
                  )}
                  <div ref={bottomRef} />
                </div>
              )}
            </ScrollArea>

            {/* Input */}
            <div className="flex items-center gap-2 px-4 py-3 border-t bg-card shrink-0">
              <Input
                className="flex-1"
                placeholder="Type a message..."
                value={text}
                onChange={(e) => handleTextChange(e.target.value)}
                onKeyDown={handleKeyDown}
                maxLength={1000}
              />
              <Button size="icon" onClick={handleSend} disabled={!text.trim()}>
                <Send className="h-4 w-4" />
              </Button>
            </div>
          </>
        )}
      </div>
    </div>
  )
}

function ChatImagePreview({ imageFileId, token }: { imageFileId: string; token: string }) {
  const [src, setSrc] = useState<string>("")
  const [failed, setFailed] = useState(false)

  useEffect(() => {
    let active = true
    let objectUrl = ""

    const load = async () => {
      try {
        setFailed(false)
        const response = await fetch(mediaStreamUrl(imageFileId), {
          headers: token ? { Authorization: `Bearer ${token}` } : {},
        })

        if (!response.ok) {
          throw new Error(`Failed image fetch: ${response.status}`)
        }

        const blob = await response.blob()
        if (!active) return
        objectUrl = URL.createObjectURL(blob)
        setSrc(objectUrl)
      } catch {
        if (!active) return
        setFailed(true)
      }
    }

    void load()

    return () => {
      active = false
      if (objectUrl) URL.revokeObjectURL(objectUrl)
    }
  }, [imageFileId, token])

  if (failed) {
    return (
      <div className="w-56 h-44 rounded-xl bg-muted/50 border flex items-center justify-center text-xs text-muted-foreground">
        Failed to load image
      </div>
    )
  }

  if (!src) {
    return <div className="w-56 h-44 rounded-xl bg-muted/50 animate-pulse" />
  }

  return (
    <img
      src={src}
      alt="chat attachment"
      className="w-56 h-44 rounded-xl object-cover mb-2"
      loading="lazy"
    />
  )
}
