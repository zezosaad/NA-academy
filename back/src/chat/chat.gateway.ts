import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Types } from 'mongoose';
import { ChatService } from './chat.service.js';
import { MessageStatus, ChatMessageType } from './schemas/message.schema.js';
import { FcmService } from '../notifications/fcm.service.js';
import { PushTokensService } from '../push-tokens/push-tokens.service.js';

@WebSocketGateway({
  namespace: 'chat',
  cors: { origin: '*' },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(ChatGateway.name);
  private userSockets = new Map<string, string>(); // userId -> socketId map

  constructor(
    private readonly chatService: ChatService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly fcmService: FcmService,
    private readonly pushTokensService: PushTokensService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token =
        client.handshake.auth?.token || client.handshake.headers?.authorization?.split(' ')[1];
      if (!token) {
        client.disconnect();
        return;
      }

      const secret = this.configService.get<string>('jwt.secret');
      const payload = this.jwtService.verify(token, { secret });

      const userId = payload.sub;
      client.data.user = payload;

      this.userSockets.set(userId.toString(), client.id);

      // Send pending offline messages
      const pending = await this.chatService.getPendingMessages(userId.toString());
      if (pending.length > 0) {
        const wired = pending.map((msg) => this.wireOutboundMessage(msg, null));
        client.emit('pending_messages', wired);
        for (const msg of pending) {
          await this.chatService.updateMessageStatus(msg._id.toString(), MessageStatus.DELIVERED);
        }
      }

      this.logger.log(`Client connected: ${client.id} (User: ${userId})`);
    } catch (error) {
      this.logger.error(`Handshake invalid for client ${client.id}`);
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    const userId = client.data?.user?.sub;
    if (userId) {
      this.userSockets.delete(userId.toString());
    }
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  /** Normalize Mongoose payloads for socket.io-json / mobile clients (string ids + ISO dates). */
  private wireOutboundMessage(savedMessage: { toObject: () => Record<string, unknown> }, clientMessageId: string | null) {
    const o = savedMessage.toObject() as Record<string, unknown>;
    const snd = o.senderId as Record<string, unknown> | string | undefined;
    const senderWire =
      snd && typeof snd === 'object'
        ? {
            _id: String((snd['_id'] as { toString: () => string })?.toString?.() ?? snd['_id']),
            name: snd['name'] !== undefined ? String(snd['name']) : '',
            role: snd['role'] !== undefined ? String(snd['role']) : '',
            email: snd['email'] !== undefined ? String(snd['email']) : '',
          }
        : String(snd ?? '');

    const toIso = (v: unknown): string => {
      if (v instanceof Date) return v.toISOString();
      if (typeof v === 'string') {
        const t = Date.parse(v);
        if (!Number.isNaN(t)) return new Date(t).toISOString();
      }
      if (typeof v === 'number') return new Date(v).toISOString();
      return new Date().toISOString();
    };
    const createdAt = toIso(o['createdAt']);
    const updatedAt = toIso(o['updatedAt']);

    return {
      _id: String(o['_id']),
      conversationId: String(o['conversationId']),
      senderId: senderWire,
      recipientId: String(o['recipientId']),
      messageType: o['messageType'],
      text: o['text'],
      imageFileId: o['imageFileId'],
      status: o['status'],
      createdAt,
      updatedAt,
      clientMessageId,
    };
  }

  @SubscribeMessage('send_message')
  async handleMessage(
    @MessageBody()
    payload: {
      recipientId: string;
      text?: string;
      imageFileId?: string;
      messageType: ChatMessageType;
      clientMessageId?: string;
    },
    @ConnectedSocket() client: Socket,
  ) {
    const senderId = client.data.user.sub;

    const canChat = await this.chatService.canChat(senderId, payload.recipientId);
    if (!canChat) {
      this.logger.warn(
        `send_message rejected unauthorized sender=${senderId} recipient=${payload.recipientId} clientMsgId=${payload.clientMessageId ?? 'n/a'}`,
      );
      client.emit('unauthorized_conversation', {
        message: 'You are not authorized to chat with this user',
        recipientId: payload.recipientId,
      });
      return { event: 'error', data: 'Unauthorized to chat with this user' };
    }

    const conversation = await this.chatService.findOrCreateConversation(
      senderId,
      payload.recipientId,
    );

    const savedMessage = await this.chatService.saveMessage({
      conversationId: conversation._id.toString(),
      senderId,
      recipientId: payload.recipientId,
      messageType: payload.messageType,
      text: payload.text,
      imageFileId: payload.imageFileId,
    });

    const messagePayload = this.wireOutboundMessage(
      savedMessage,
      payload.clientMessageId ?? null,
    );

    this.logger.log(
      `send_message sender=${senderId} recipient=${payload.recipientId} msg=${String(savedMessage._id)} conversation=${conversation._id.toString()} clientMsgId=${payload.clientMessageId ?? 'n/a'} recipientOnline=${this.userSockets.has(payload.recipientId)}`,
    );

    const recipientSocketId = this.userSockets.get(payload.recipientId);
    if (recipientSocketId) {
      this.server.to(recipientSocketId).emit('new_message', messagePayload);
    }

    client.emit('new_message', messagePayload);

    void this.sendChatPush(savedMessage, payload.recipientId, messagePayload);

    const recipientIsAdmin = await this.chatService.isAdminUser(payload.recipientId);
    const senderIsAdmin = await this.chatService.isAdminUser(senderId);

    if (recipientIsAdmin && !senderIsAdmin) {
      const autoReply = await this.chatService.saveMessage({
        conversationId: conversation._id.toString(),
        senderId: payload.recipientId,
        recipientId: senderId,
        messageType: ChatMessageType.TEXT,
        text: this.chatService.getAutoReplyText(),
      });

      const autoReplyPayload = this.wireOutboundMessage(autoReply, null);

      client.emit('new_message', autoReplyPayload);

      const adminSocketId = this.userSockets.get(payload.recipientId);
      if (adminSocketId) {
        this.server.to(adminSocketId).emit('new_message', autoReplyPayload);
      }

      void this.sendChatPush(autoReply, senderId, autoReplyPayload);
    }

    return {
      event: 'message_ack',
      data: {
        messageId: savedMessage._id.toString(),
        status: MessageStatus.SENT,
        clientMessageId: payload.clientMessageId ?? null,
      },
    };
  }

  private async sendChatPush(
    savedMessage: { _id: unknown; conversationId: unknown; messageType?: ChatMessageType; text?: string | null },
    recipientId: string,
    wired: { senderId: unknown; text?: unknown; messageType?: unknown },
  ): Promise<void> {
    try {
      if (!Types.ObjectId.isValid(recipientId)) return;
      const recipientObjectId = new Types.ObjectId(recipientId);
      const tokens = await this.pushTokensService.findActiveForUserIds([recipientObjectId]);
      if (tokens.length === 0) return;

      const senderWire = wired.senderId as { _id?: string; name?: string } | string | undefined;
      const senderId =
        typeof senderWire === 'object' && senderWire
          ? String(senderWire._id ?? '')
          : String(senderWire ?? '');
      const senderName =
        typeof senderWire === 'object' && senderWire ? String(senderWire.name ?? '') : '';

      const isImage = (wired.messageType ?? savedMessage.messageType) === ChatMessageType.IMAGE;
      const text = (wired.text as string | undefined) ?? savedMessage.text ?? '';
      const body = isImage ? '📷 صورة' : text;

      const messageId = String((savedMessage._id as { toString: () => string }).toString());
      const conversationId = String(
        (savedMessage.conversationId as { toString: () => string }).toString(),
      );

      const result = await this.fcmService.sendBatch(
        tokens.map((t) => t.token),
        {
          title: senderName || 'رسالة جديدة',
          body,
          data: {
            type: 'chat',
            conversationId,
            senderId,
            senderName,
            messageId,
          },
        },
      );
      this.logger.log(
        `chat push sent recipient=${recipientId} success=${result.successCount} failed=${result.failureCount}`,
      );
    } catch (err) {
      this.logger.error(`chat push failed recipient=${recipientId}`, err as Error);
    }
  }

  @SubscribeMessage('delivery_ack')
  async handleDelivery(@MessageBody() payload: { messageId: string; senderId: string }) {
    await this.chatService.updateMessageStatus(payload.messageId, MessageStatus.DELIVERED);
    const senderSocketId = this.userSockets.get(payload.senderId);
    if (senderSocketId) {
      this.server
        .to(senderSocketId)
        .emit('status_update', { messageId: payload.messageId, status: MessageStatus.DELIVERED });
    }
  }

  @SubscribeMessage('mark_read')
  async handleMarkRead(
    @MessageBody() payload: { conversationId: string; senderId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const readerId = client.data.user.sub;
    await this.chatService.markConversationRead(payload.conversationId, readerId);

    const senderSocketId = this.userSockets.get(payload.senderId);
    if (senderSocketId) {
      this.server
        .to(senderSocketId)
        .emit('conversation_read', { conversationId: payload.conversationId });
    }
  }

  @SubscribeMessage('typing')
  handleTyping(
    @MessageBody() payload: { recipientId: string; isTyping: boolean },
    @ConnectedSocket() client: Socket,
  ) {
    const recipientSocketId = this.userSockets.get(payload.recipientId);
    if (recipientSocketId) {
      this.server
        .to(recipientSocketId)
        .emit('typing_indicator', { userId: client.data.user.sub, isTyping: payload.isTyping });
    }
  }
}
