const API_BASE = import.meta.env.VITE_API_BASE_URL ?? 'https://api.progarage.cloud/api';

export function getToken(): string | null {
  return localStorage.getItem('pg_admin_token');
}

export function setToken(token: string | null) {
  if (token) localStorage.setItem('pg_admin_token', token);
  else localStorage.removeItem('pg_admin_token');
}

async function request<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const headers: Record<string, string> = {
    Accept: 'application/json',
    ...(options.body ? { 'Content-Type': 'application/json' } : {}),
    ...(options.headers as Record<string, string> | undefined),
  };
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers });
  const json = await res.json().catch(() => ({}));

  if (!res.ok) {
    const msg =
      (json as { error?: { message?: string } }).error?.message ??
      `Request failed (${res.status})`;
    throw new Error(msg);
  }

  return json as T;
}

export async function loginStaff(login: string, pin: string) {
  const data = await request<{
    success: boolean;
    data: { token: string; user: { is_platform_admin: boolean } };
  }>('/auth/staff/login', {
    method: 'POST',
    body: JSON.stringify({ login, pin }),
  });
  if (!data.data.user.is_platform_admin) {
    throw new Error('This account is not a platform administrator.');
  }
  setToken(data.data.token);
}

export const api = {
  tenants: (params?: string) =>
    request<{ success: boolean; data: Tenant[] }>(`/platform/tenants${params ? `?${params}` : ''}`),
  tenant: (uuid: string) =>
    request<{ success: boolean; data: Tenant }>(`/platform/tenants/${uuid}`),
  createTenant: (body: Record<string, unknown>) =>
    request('/platform/tenants', { method: 'POST', body: JSON.stringify(body) }),
  updateTenant: (uuid: string, body: Record<string, unknown>) =>
    request(`/platform/tenants/${uuid}`, { method: 'PATCH', body: JSON.stringify(body) }),
  deleteTenant: (uuid: string) =>
    request(`/platform/tenants/${uuid}`, { method: 'DELETE' }),
  resetTenant: (uuid: string, resetOnboarding: boolean) =>
    request(`/platform/tenants/${uuid}/reset-data`, {
      method: 'POST',
      body: JSON.stringify({ reset_onboarding: resetOnboarding }),
    }),
  updateSubscription: (uuid: string, body: Record<string, unknown>) =>
    request(`/platform/tenants/${uuid}/subscription`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    }),
  plans: () => request<{ success: boolean; data: Plan[] }>('/platform/plans'),
  createPlan: (body: Record<string, unknown>) =>
    request('/platform/plans', { method: 'POST', body: JSON.stringify(body) }),
  updatePlan: (uuid: string, body: Record<string, unknown>) =>
    request(`/platform/plans/${uuid}`, { method: 'PATCH', body: JSON.stringify(body) }),
  archivePlan: (uuid: string) =>
    request(`/platform/plans/${uuid}`, { method: 'DELETE' }),
  users: (tenantUuid: string) =>
    request<{ success: boolean; data: PlatformUser[] }>(`/platform/users/tenant/${tenantUuid}`),
  createUser: (tenantUuid: string, body: Record<string, unknown>) =>
    request(`/platform/users/tenant/${tenantUuid}`, {
      method: 'POST',
      body: JSON.stringify(body),
    }),
  updateUser: (tenantUuid: string, userUuid: string, body: Record<string, unknown>) =>
    request(`/platform/users/tenant/${tenantUuid}/${userUuid}`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    }),
  deleteUser: (tenantUuid: string, userUuid: string) =>
    request(`/platform/users/tenant/${tenantUuid}/${userUuid}`, { method: 'DELETE' }),
  storageFiles: (disk: string, prefix: string, tenantUuid?: string) => {
    const q = new URLSearchParams({ disk, prefix });
    if (tenantUuid) q.set('tenant_uuid', tenantUuid);
    return request<{ success: boolean; data: StorageListing }>(`/platform/storage/files?${q}`);
  },
  deleteFile: (disk: string, path: string) =>
    request('/platform/storage/files', {
      method: 'DELETE',
      body: JSON.stringify({ disk, path }),
    }),
};

export type Tenant = {
  uuid: string;
  business_name: string;
  status: string;
  phone?: string;
  email?: string;
  setup_step?: string;
  setup_complete?: boolean;
  owner?: { uuid: string; name: string; phone: string; requires_pin_setup: boolean };
  subscription?: { status: string; plan_name?: string; plan_slug?: string };
};

export type Plan = {
  uuid: string;
  name: string;
  slug: string;
  price: number;
  trial_days: number;
  billing_cycle: string;
  status: string;
  max_users: number;
};

export type PlatformUser = {
  uuid: string;
  first_name: string;
  last_name: string;
  phone: string;
  role: string;
  requires_pin_setup: boolean;
};

export type StorageListing = {
  disk: string;
  prefix: string;
  files: { path: string; size: number; url?: string }[];
};
