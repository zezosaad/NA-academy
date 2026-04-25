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
import { ChatService } from './chat.service.js';
import { MessageStatus } from './schemas/message.schema.js';

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
        client.emit('pending_messages', pending);
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

  @SubscribeMessage('send_message')
  async handleMessage(
    @MessageBody()
    payload: { recipientId: string; text?: string; imageFileId?: string; messageType: any; clientMessageId?: string },
    @ConnectedSocket() client: Socket,
  ) {
    const senderId = client.data.user.sub;

    const canChat = await this.chatService.canChat(senderId, payload.recipientId);
    if (!canChat) {
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
      text: payload.text,
      imageFileId: payload.imageFileId,
      messageType: payload.messageType,
    });

    const messagePayload: Record<string, any> = {
      ...savedMessage.toObject(),
      clientMessageId: payload.clientMessageId ?? null,
    };

    const recipientSocketId = this.userSockets.get(payload.recipientId);
    if (recipientSocketId) {
      this.server.to(recipientSocketId).emit('new_message', messagePayload);
    }

    client.emit('new_message', messagePayload);

    return {
      event: 'message_ack',
      data: { messageId: savedMessage._id, status: MessageStatus.SENT, clientMessageId: payload.clientMessageId ?? null },
    };
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
