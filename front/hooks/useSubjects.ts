import { useState, useEffect, useCallback } from 'react';
import { SubjectsService } from '../services/subjects.service';
import { Subject, SubjectsQueryParams } from '../types/subject';

export const useSubjects = (initialParams?: SubjectsQueryParams) => {
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(initialParams?.page || 1);
  const [hasMore, setHasMore] = useState(true);

  const limit = initialParams?.limit || 20;

  const fetchSubjects = useCallback(async (pageNum: number, isRefresh = false) => {
    try {
      if (isRefresh) setRefreshing(true);
      else if (pageNum === 1) setLoading(true);

      const response = await SubjectsService.getAll({
        ...initialParams,
        page: pageNum,
        limit,
      });

      const newData = response.data;
      setTotal(response.total);
      setHasMore(pageNum * limit < response.total);

      if (pageNum === 1) {
        setSubjects(newData);
      } else {
        setSubjects((prev) => [...prev, ...newData]);
      }
      setPage(pageNum);
    } catch (error) {
      console.error('Failed to fetch subjects', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [initialParams, limit]);

  useEffect(() => {
    fetchSubjects(1);
  }, [fetchSubjects]);

  const refresh = useCallback(() => {
    fetchSubjects(1, true);
  }, [fetchSubjects]);

  const loadMore = useCallback(() => {
    if (!loading && hasMore) {
      fetchSubjects(page + 1);
    }
  }, [loading, hasMore, page, fetchSubjects]);

  return { subjects, loading, refreshing, total, hasMore, refresh, loadMore };
};
