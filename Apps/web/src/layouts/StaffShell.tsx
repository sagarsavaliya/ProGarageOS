import type { ReactNode } from 'react';
import { NavLink } from 'react-router-dom';
import { Button } from '@/components/ui/Button';

const STAFF_NAV_SECTIONS = [
  {
    section: 'MAIN',
    items: [
      { to: '/dashboard', label: 'Dashboard' },
      { to: '/jobs', label: 'Jobs' },
      { to: '/customers', label: 'Customers' },
      { to: '/vehicles', label: 'Vehicles' },
      { to: '/appointments', label: 'Appointments' },
    ],
  },
  {
    section: 'OPERATIONS',
    items: [
      { to: '/inventory', label: 'Inventory' },
      { to: '/billing', label: 'Billing' },
      { to: '/reports', label: 'Reports' },
    ],
  },
  {
    section: 'SYSTEM',
    items: [
      { to: '/settings', label: 'Settings' },
      { to: '/notifications', label: 'Notifications' },
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
          <h1>GarageFlow</h1>
          <p>Garage Operations</p>
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
                    {item.label}
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
            <p>{props.subtitle ?? 'Garage operations workspace'}</p>
          </div>
          <div className="header-user">{props.userName ?? 'Staff User'}</div>
        </header>
        <section className="page-content">{props.children}</section>
      </main>
    </div>
  );
}
