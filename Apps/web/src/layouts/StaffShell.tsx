import type { ReactNode } from 'react';
import { NavLink } from 'react-router-dom';
import { Button } from '@/components/ui/Button';

const NAV_ICONS: Record<string, ReactNode> = {
  '/dashboard': (
    <svg className="nav-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden>
      <rect x="3" y="3" width="7" height="7" rx="1.5" />
      <rect x="14" y="3" width="7" height="7" rx="1.5" />
      <rect x="3" y="14" width="7" height="7" rx="1.5" />
      <rect x="14" y="14" width="7" height="7" rx="1.5" />
    </svg>
  ),
  '/jobs': (
    <svg className="nav-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden>
      <path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2" />
      <rect x="9" y="3" width="6" height="4" rx="1" />
      <path d="M9 12h6M9 16h4" />
    </svg>
  ),
  '/customers': (
    <svg className="nav-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden>
      <circle cx="9" cy="8" r="3.5" />
      <path d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6" />
      <path d="M16 7.5a3 3 0 1 1 0 6M19 20c0-2.5-1.5-4.5-3.5-5.5" />
    </svg>
  ),
  '/vehicles': (
    <svg className="nav-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden>
      <path d="M5 17h2M17 17h2" />
      <path d="M3 12l1.5-4.5A2 2 0 0 1 6.4 6h11.2a2 2 0 0 1 1.9 1.5L21 12" />
      <rect x="3" y="12" width="18" height="5" rx="1" />
    </svg>
  ),
  '/appointments': (
    <svg className="nav-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden>
      <rect x="3" y="5" width="18" height="16" rx="2" />
      <path d="M16 3v4M8 3v4M3 10h18" />
    </svg>
  ),
  '/inventory': (
    <svg className="nav-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden>
      <path d="M21 8l-9-5-9 5v8l9 5 9-5V8z" />
      <path d="M12 3v18M3 8l9 5 9-5" />
    </svg>
  ),
  '/billing': (
    <svg className="nav-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden>
      <rect x="3" y="6" width="18" height="14" rx="2" />
      <path d="M7 10h4M7 14h6" />
      <path d="M17 6V4a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v2" />
    </svg>
  ),
  '/reports': (
    <svg className="nav-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden>
      <path d="M4 19V5M4 19h16" />
      <path d="M8 15V9M12 15V7M16 15v-4" />
    </svg>
  ),
  '/settings': (
    <svg className="nav-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden>
      <circle cx="12" cy="12" r="3" />
      <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" />
    </svg>
  ),
  '/notifications': (
    <svg className="nav-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden>
      <path d="M15 17H9l-1-2H5a2 2 0 0 1-2-2v-1a7 7 0 0 1 14 0v1a2 2 0 0 1-2 2h-3l-1 2z" />
      <path d="M10 20a2 2 0 0 0 4 0" />
    </svg>
  ),
  '/audit': (
    <svg className="nav-item-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden>
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <path d="M14 2v6h6M9 13h6M9 17h4" />
    </svg>
  ),
};

function userInitials(name?: string): string {
  if (!name) {
    return 'ST';
  }
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? '')
    .join('');
}

const STAFF_NAV_SECTIONS = [
  {
    section: 'Main',
    items: [
      { to: '/dashboard', label: 'Dashboard' },
      { to: '/jobs', label: 'Jobs' },
      { to: '/customers', label: 'Customers' },
      { to: '/vehicles', label: 'Vehicles' },
      { to: '/appointments', label: 'Appointments' },
    ],
  },
  {
    section: 'Operations',
    items: [
      { to: '/inventory', label: 'Inventory' },
      { to: '/billing', label: 'Billing' },
      { to: '/reports', label: 'Reports' },
    ],
  },
  {
    section: 'System',
    items: [
      { to: '/settings', label: 'Settings' },
      { to: '/notifications', label: 'Notifications' },
      { to: '/audit', label: 'Audit' },
    ],
  },
] as const;

export function StaffShell(props: {
  title: string;
  subtitle?: string;
  userName?: string;
  onLogout: () => void;
  children: ReactNode;
}) {
  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="sidebar-brand-mark" aria-hidden>
            GF
          </div>
          <div>
            <h1>GarageFlow</h1>
            <p>Operations Platform</p>
          </div>
        </div>

        <nav className="sidebar-nav-grouped">
          {STAFF_NAV_SECTIONS.map((group) => (
            <div key={group.section} className="sidebar-group">
              <div className="sidebar-group-title">{group.section}</div>
              <div className="sidebar-nav">
                {group.items.map((item) => (
                  <NavLink
                    to={item.to}
                    key={item.to}
                    className={({ isActive }) => (isActive ? 'nav-item active' : 'nav-item')}
                  >
                    {NAV_ICONS[item.to]}
                    <span>{item.label}</span>
                  </NavLink>
                ))}
              </div>
            </div>
          ))}
        </nav>

        <Button className="sidebar-logout" variant="outline" onClick={props.onLogout}>
          Logout
        </Button>
      </aside>

      <main className="page-wrap">
        <header className="page-header">
          <div>
            <h2>{props.title}</h2>
            <p>{props.subtitle ?? 'Manage your garage operations'}</p>
          </div>
          <div className="header-user">
            <span className="header-user-avatar">{userInitials(props.userName)}</span>
            <span>{props.userName ?? 'Staff User'}</span>
          </div>
        </header>
        <section className="page-content">{props.children}</section>
      </main>
    </div>
  );
}
