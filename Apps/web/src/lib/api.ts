export type QueryValue = string | number | boolean | undefined | null;
export type QueryMap = Record<string, QueryValue>;
export type JsonMap = Record<string, unknown>;

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'https://api.progarage.cloud/api';

export class ApiError extends Error {
  public readonly status: number;

  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

function buildQuery(params?: QueryMap): string {
  if (!params) {
    return '';
  }

  const search = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value === undefined || value === null || value === '') {
      return;
    }
    search.set(key, String(value));
  });

  const encoded = search.toString();
  return encoded ? `?${encoded}` : '';
}

export async function apiRequest<T = unknown>(
  path: string,
  options: {
    method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
    token?: string | null;
    query?: QueryMap;
    body?: unknown;
  } = {},
): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}${buildQuery(options.query)}`, {
    method: options.method ?? 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...(options.token ? { Authorization: `Bearer ${options.token}` } : {}),
    },
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
  });

  const text = await response.text();
  const payload = text ? (JSON.parse(text) as JsonMap) : {};

  if (!response.ok) {
    const nestedError = payload.error as JsonMap | undefined;
    const message =
      (nestedError?.message as string | undefined) ??
      (payload.message as string | undefined) ??
      `Request failed with status ${response.status}`;
    throw new ApiError(message, response.status);
  }

  return payload as T;
}

export function asData<T>(payload: unknown): T {
  if (payload && typeof payload === 'object' && 'data' in (payload as JsonMap)) {
    return (payload as { data: T }).data;
  }
  return payload as T;
}

export function asList<T>(payload: unknown): { items: T[]; meta?: JsonMap } {
  if (Array.isArray(payload)) {
    return { items: payload as T[] };
  }
  if (!payload || typeof payload !== 'object') {
    return { items: [] };
  }

  const map = payload as JsonMap;
  if (Array.isArray(map.data)) {
    return { items: map.data as T[], meta: (map.meta as JsonMap | undefined) ?? undefined };
  }

  const inner = map.data as JsonMap | undefined;
  if (inner && Array.isArray(inner.items)) {
    return { items: inner.items as T[], meta: (inner.meta as JsonMap | undefined) ?? undefined };
  }

  return { items: [] };
}

export function extractToken(payload: unknown): string {
  if (!payload || typeof payload !== 'object') {
    return '';
  }
  const map = payload as JsonMap;
  if (typeof map.token === 'string') {
    return map.token;
  }
  const data = map.data as JsonMap | undefined;
  return typeof data?.token === 'string' ? data.token : '';
}

export function normalizeLogin(value: string): string {
  const trimmed = value.trim();
  if (/^\d{10}$/.test(trimmed)) {
    return `+91${trimmed}`;
  }
  return trimmed;
}
