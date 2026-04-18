export enum MediaType {
  VIDEO = 'video',
  IMAGE = 'image',
}

export interface MediaAsset {
  _id: string;
  gridFsFileId: string;
  subjectId: string;
  filename: string;
  contentType: string;
  fileSize: number;
  mediaType: MediaType;
  title?: string;
  order?: number;
  uploadedBy?: string;
  createdAt: string;
  updatedAt: string;
}
