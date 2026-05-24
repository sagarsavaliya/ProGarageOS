export type PortalType = 'admin' | 'staff';

const ENV_PORTAL = import.meta.env.VITE_PORTAL;

export function getActivePortal(): PortalType {
  if (ENV_PORTAL === 'admin' || ENV_PORTAL === 'staff') {
    return ENV_PORTAL;
  }
  return window.location.hostname.startsWith('admin.') ? 'admin' : 'staff';
}

export const ACTIVE_PORTAL = getActivePortal();

export function getTokenStorageKey(portal: PortalType): string {
  return portal === 'admin' ? 'pg_admin_token' : 'pg_staff_token';
}
