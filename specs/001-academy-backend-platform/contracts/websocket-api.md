# WebSocket API Contracts: NA-Academy Backend Platform

**Date**: 2026-04-17  
**Transport**: Socket.io  
**Namespace**: `/chat`  
**Auth**: JWT token passed in `handshake.auth.token`

---

## Connection

### Handshake

```javascript
const socket = io('/chat', {
  auth: { token: 'eyJhbG...' }
});
```

**Server behavior on connect**:
1. Verify JWT from `handshake.auth.token`
2. Validate session exists in DB (single-session enforcement)
3. Attach user to `socket.data.user`
4. Join all conversation rooms for this user
5. Flush pending messages (status = `sent`, recipient = this user)
6. Track user as online in memory map

**On auth failure**: Emit `error` event with `{ message: 'Unauthorized' }`, disconnect.

---

## Client → Server Events

### `send_message`

Send a text or image message to a conversation.

**Payload**:
```json
{
  "recipientId": "userId",
  "messageType": "text",
  "text": "Hello teacher!",
  "imageFileId": null
}
```

For image messages: upload image via `POST /api/v1/media/chat/upload` first, then send with `messageType: "image"` and `imageFileId`.

**Server behavior**:
1. Validate sender has an activated subject in common with recipient (subject-gated check)
2. Find or create Conversation
3. Persist Message with `status: sent`
4. Emit `message_ack` to sender
5. If recipient is online: emit `new_message` to recipient's room

---

### `delivery_ack`

Client acknowledges receipt of a message.

**Payload**:
```json
{
  "messageId": "messageObjectId"
}
```

**Server behavior**:
1. Update message `status` from `sent` → `delivered`
2. Emit `status_update` to sender

---

### `mark_read`

Client marks all messages in a conversation as read.

**Payload**:
```json
{
  "conversationId": "conversationObjectId",
  "lastMessageId": "messageObjectId"
}
```

**Server behavior**:
1. Bulk-update all messages in conversation where `recipientId = currentUser AND status != read AND createdAt <= lastMessage.createdAt` → `status: read`
2. Emit `status_update` to sender for each updated message (or batched)

---

### `typing`

Indicate typing status.

**Payload**:
```json
{
  "conversationId": "conversationObjectId",
  "isTyping": true
}
```

**Server behavior**: Broadcast `typing_indicator` to the other participant in the room.

---

## Server → Client Events

### `message_ack`

Acknowledges successful persistence of a sent message.

**Payload**:
```json
{
  "messageId": "newMessageObjectId",
  "conversationId": "conversationObjectId",
  "status": "sent",
  "createdAt": "2026-04-17T10:05:00.000Z"
}
```

---

### `new_message`

Delivers a new message to the recipient.

**Payload**:
```json
{
  "messageId": "...",
  "conversationId": "...",
  "senderId": "...",
  "senderName": "Ahmed Hassan",
  "messageType": "text",
  "text": "Hello teacher!",
  "imageFileId": null,
  "createdAt": "2026-04-17T10:05:00.000Z"
}
```

**Client must**: Emit `delivery_ack` upon receiving this event.

---

### `status_update`

Notifies the original sender of a status change on their message.

**Payload**:
```json
{
  "messageId": "...",
  "status": "delivered"
}
```

Or batched:
```json
{
  "conversationId": "...",
  "messageIds": ["msg1", "msg2", "msg3"],
  "status": "read"
}
```

---

### `typing_indicator`

**Payload**:
```json
{
  "conversationId": "...",
  "userId": "...",
  "isTyping": true
}
```

---

### `error`

Server-side error notification.

**Payload**:
```json
{
  "message": "Unauthorized",
  "code": "AUTH_FAILED"
}
```

---

### `session_terminated`

Pushed when the server terminates the session (security flag, new login elsewhere).

**Payload**:
```json
{
  "reason": "security_flag" | "new_login",
  "message": "Your session was terminated due to a security concern."
}
```

**Client must**: Disconnect and redirect to login.

---

## Chat Image Upload (via REST)

### POST /api/v1/media/chat/upload `@Roles(student, teacher)`

**Content-Type**: `multipart/form-data`

**Form fields**:
- `file`: Image file (max 20MB)

**Response 201**:
```json
{
  "fileId": "gridFsObjectId",
  "contentType": "image/jpeg",
  "fileSize": 245000
}
```

Use the returned `fileId` in the `send_message` socket event as `imageFileId`.

---

## Room Strategy

- Room ID: deterministic from sorted participant IDs: `sorted([userA, userB]).join(':')`
- Users join all their conversation rooms on connect
- Messages are emitted to the room, ensuring both participants receive them
- No global broadcast — all messages scoped to rooms
