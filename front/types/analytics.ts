export interface WatchTimePayload {
  mediaAssetId: string;
  durationSeconds: number;
}

export interface StudentAnalytics {
  totalWatchTimeSeconds: number;
  totalExamsCompleted: number;
  averageScore: number;
  certificates: number;
  subjectBreakdown: {
    subjectId: string;
    subjectTitle: string;
    watchTimeSeconds: number;
    examsCompleted: number;
  }[];
}
