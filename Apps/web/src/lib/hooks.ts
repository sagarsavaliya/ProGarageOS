import { useQuery } from '@tanstack/react-query';
import { apiRequest, asList, type JsonMap, type QueryMap } from '@/lib/api';

export function usePaginatedList(path: string, token: string, query?: QueryMap) {
  return useQuery({
    queryKey: ['list', path, query, token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest(path, { token, query });
      return asList<JsonMap>(payload);
    },
  });
}

export function useDetail(path: string, token: string, enabled = true) {
  return useQuery({
    queryKey: ['detail', path, token],
    enabled: enabled && token.length > 0 && path.length > 0,
    queryFn: () => apiRequest(path, { token }),
  });
}
