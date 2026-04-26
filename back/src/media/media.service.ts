import {
  Injectable,
  NotFoundException,
  BadRequestException,
  PayloadTooLargeException,
  UnsupportedMediaTypeException,
  Logger,
} from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, Types, mongo } from 'mongoose';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import { Transform, TransformCallback } from 'stream';
import busboy from 'busboy';
import { MediaAsset, MediaAssetDocument, MediaType } from './schemas/media-asset.schema.js';
import { UploadMediaDto } from './dto/upload-media.dto.js';
import { MediaResponseDto } from './dto/media-response.dto.js';

@Injectable()
export class MediaService {
  private readonly logger = new Logger(MediaService.name);
  private readonly mediaBucket: mongo.GridFSBucket;
  private readonly chatBucket: mongo.GridFSBucket;

  constructor(
    @InjectConnection() private readonly connection: Connection,
    @InjectModel(MediaAsset.name) private readonly mediaAssetModel: Model<MediaAssetDocument>,
    private readonly configService: ConfigService,
  ) {
    const db = this.connection.db;
    if (!db) {
      throw new Error('Database connection not established');
    }

    this.mediaBucket = new mongo.GridFSBucket(db, {
      bucketName: 'media',
      chunkSizeBytes: this.configService.get<number>('gridfs.videoChunkSize') || 1048576,
    });

    this.chatBucket = new mongo.GridFSBucket(db, {
      bucketName: 'chatFiles',
      chunkSizeBytes: this.configService.get<number>('gridfs.chatChunkSize') || 261120, // 256KB roughly
    });
  }

  async uploadMedia(req: Request, userId: string): Promise<MediaResponseDto> {
    return new Promise((resolve, reject) => {
      const bb = busboy({ headers: req.headers });

      const uploadDto: Partial<UploadMediaDto> = {};
      let filename = '';
      let contentType = '';
      let fileReceived = false;

      bb.on('field', (name, val) => {
        uploadDto[name as keyof UploadMediaDto] = val as any;
      });

      bb.on('file', (name, stream, info) => {
        if (name !== 'file') {
          stream.resume();
          return;
        }
        fileReceived = true;
        filename = info.filename;
        contentType = info.mimeType;

        const writeStream = this.mediaBucket.openUploadStream(filename, {
          metadata: { contentType },
        });

        stream.pipe(writeStream);

        writeStream.on('finish', async () => {
          try {
            const fileId = writeStream.id as Types.ObjectId;

            if (!uploadDto.subjectId || !uploadDto.mediaType) {
              await this.mediaBucket.delete(fileId);
              return reject(new BadRequestException('subjectId and mediaType are required'));
            }

            const files = await this.mediaBucket.find({ _id: fileId }).toArray();
            const uploadedFile = files[0];

            if (!uploadedFile) {
              return reject(new Error('Uploaded file not found in GridFS'));
            }

            const asset = new this.mediaAssetModel({
              gridFsFileId: fileId,
              subjectId: new Types.ObjectId(uploadDto.subjectId),
              filename,
              contentType,
              fileSize: uploadedFile.length,
              mediaType: uploadDto.mediaType,
              title: uploadDto.title,
              uploadedBy: new Types.ObjectId(userId),
            });

            await asset.save();
            this.logger.log(`Uploaded media: ${asset._id} (${filename})`);

            resolve({
              id: asset._id.toString(),
              gridFsFileId: fileId.toString(),
              filename,
              contentType: asset.contentType,
              fileSize: asset.fileSize,
              mediaType: asset.mediaType,
              title: asset.title,
            });
          } catch (error) {
            if (writeStream.id) {
              await this.mediaBucket.delete(writeStream.id as Types.ObjectId);
            }
            reject(error);
          }
        });

        writeStream.on('error', (error) => {
          reject(error);
        });
      });

      bb.on('error', (err: Error) => {
        reject(err);
      });

      bb.on('finish', () => {
        if (!fileReceived) {
          reject(new BadRequestException('No file provided'));
        }
      });

      req.pipe(bb);
    });
  }

  async findAssetById(id: string): Promise<MediaAssetDocument | null> {
    return this.mediaAssetModel.findById(id).exec();
  }

  async streamFile(
    id: string,
    headers: any,
    preFetchedAsset?: MediaAssetDocument | null,
  ): Promise<{
    stream: NodeJS.ReadableStream;
    headers: Record<string, string | number>;
    status: number;
  }> {
    const asset = preFetchedAsset || (await this.mediaAssetModel.findById(id).exec());
    if (!asset) throw new NotFoundException('Media asset not found');

    const range = headers.range;
    let start = 0;
    let end = asset.fileSize - 1;
    let status = 200;

    const resHeaders: Record<string, string | number> = {
      'Content-Type': asset.contentType,
      'Accept-Ranges': 'bytes',
    };

    if (range) {
      const parts = range.replace(/bytes=/, '').split('-');
      start = parseInt(parts[0], 10);
      end = parts[1] ? parseInt(parts[1], 10) : asset.fileSize - 1;

      if (start >= asset.fileSize) {
        throw new BadRequestException('Requested range not satisfiable');
      }

      resHeaders['Content-Range'] = `bytes ${start}-${end}/${asset.fileSize}`;
      resHeaders['Content-Length'] = end - start + 1;
      status = 206;
    } else {
      resHeaders['Content-Length'] = asset.fileSize;
    }

    const stream = this.mediaBucket.openDownloadStream(asset.gridFsFileId, {
      start,
      end: end + 1, // exclusive end
    });

    return { stream, headers: resHeaders, status };
  }

  async deleteMedia(id: string): Promise<void> {
    const asset = await this.mediaAssetModel.findById(id).exec();
    if (!asset) throw new NotFoundException('Media asset not found');

    await this.mediaBucket.delete(asset.gridFsFileId);
    await this.mediaAssetModel.deleteOne({ _id: asset._id }).exec();

    this.logger.log(`Deleted media asset: ${id}`);
  }

  async findBySubjectId(subjectId: string): Promise<MediaAssetDocument[]> {
    return this.mediaAssetModel
      .find({ subjectId: new Types.ObjectId(subjectId) })
      .sort({ order: 1, createdAt: 1 })
      .exec();
  }

  async uploadChatMedia(
    req: Request,
    userId: string,
    options: { maxBytes: number; allowedMimeTypes: Set<string> },
  ): Promise<MediaResponseDto> {
    return new Promise((resolve, reject) => {
      const bb = busboy({ headers: req.headers, limits: { fileSize: options.maxBytes } });

      let filename = '';
      let contentType = '';
      let fileReceived = false;

      bb.on('file', (name, stream, info) => {
        if (name !== 'file') {
          stream.resume();
          return;
        }
        fileReceived = true;
        filename = info.filename;
        contentType = info.mimeType;

        if (!options.allowedMimeTypes.has(contentType)) {
          stream.resume();
          reject(
            new UnsupportedMediaTypeException(
              `Unsupported file type. Allowed: ${Array.from(options.allowedMimeTypes).join(', ')}`,
            ),
          );
          return;
        }

        let totalBytes = 0;
        let sizeExceeded = false;

        const sizeCheck = new Transform({
          transform(chunk: Buffer, _encoding: string, callback: TransformCallback) {
            if (sizeExceeded) {
              callback();
              return;
            }
            totalBytes += chunk.length;
            if (totalBytes > options.maxBytes) {
              sizeExceeded = true;
              callback(
                new PayloadTooLargeException(
                  `File must be smaller than ${options.maxBytes / 1024 / 1024} MB`,
                ),
              );
              return;
            }
            callback(null, chunk);
          },
        });

        const writeStream = this.chatBucket.openUploadStream(filename, {
          metadata: { contentType, chatUpload: true },
        });

        sizeCheck.on('error', (err: Error) => {
          writeStream.destroy();
          reject(err);
        });

        stream.on('error', (err: Error) => {
          sizeCheck.destroy();
          writeStream.destroy();
          reject(err);
        });

        stream.on('limit', () => {
          sizeExceeded = true;
          sizeCheck.destroy();
          writeStream.destroy();
          reject(
            new PayloadTooLargeException(
              `File must be smaller than ${options.maxBytes / 1024 / 1024} MB`,
            ),
          );
        });

        writeStream.on('error', (error: Error) => {
          reject(error);
        });

        stream.pipe(sizeCheck).pipe(writeStream);

        writeStream.on('finish', async () => {
          try {
            if (sizeExceeded) {
              try {
                await this.chatBucket.delete(writeStream.id as Types.ObjectId);
              } catch {}
              return reject(
                new PayloadTooLargeException(
                  `File must be smaller than ${options.maxBytes / 1024 / 1024} MB`,
                ),
              );
            }

            const fileId = writeStream.id as Types.ObjectId;
            const files = await this.chatBucket.find({ _id: fileId }).toArray();
            const uploadedFile = files[0];
            if (!uploadedFile) {
              return reject(new Error('Uploaded file not found in GridFS'));
            }

            const asset = new this.mediaAssetModel({
              gridFsFileId: fileId,
              subjectId: undefined,
              filename,
              contentType,
              fileSize: uploadedFile.length,
              mediaType: MediaType.IMAGE,
              chatUpload: true,
              uploadedBy: new Types.ObjectId(userId),
            });

            await asset.save();
            this.logger.log(`Uploaded chat media: ${asset._id} (${filename})`);

            resolve({
              id: asset._id.toString(),
              gridFsFileId: fileId.toString(),
              filename,
              contentType: asset.contentType,
              fileSize: asset.fileSize,
              mediaType: asset.mediaType,
              title: asset.title,
            });
          } catch (error) {
            if (writeStream.id) {
              try {
                await this.chatBucket.delete(writeStream.id as Types.ObjectId);
              } catch {}
            }
            reject(error);
          }
        });
      });

      bb.on('error', (err: Error) => {
        reject(err);
      });

      bb.on('finish', () => {
        if (!fileReceived) {
          reject(new BadRequestException('No file provided'));
        }
      });

      req.pipe(bb);
    });
  }
}
