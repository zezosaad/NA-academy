export interface Subject {
  _id: string;
  title: string;
  description?: string;
  category: string;
  isActive: boolean;
  createdBy?: string;
  createdAt: string;
  updatedAt: string;
}

export interface SubjectBundle {
  _id: string;
  name: string;
  subjects: string[] | Subject[];
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface SubjectsListResponse {
  data: Subject[];
  total: number;
  page: number;
  limit: number;
}

export interface SubjectsQueryParams {
  page?: number;
  limit?: number;
  search?: string;
  category?: string;
  isActive?: boolean;
}
