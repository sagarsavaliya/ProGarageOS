import { FormEvent, ReactNode, useEffect, useMemo, useState } from 'react';
import {
  BrowserRouter,
  Link,
  NavLink,
  Navigate,
  Outlet,
  Route,
  Routes,
  useNavigate,
  useParams,
} from 'react-router-dom';
import {
  QueryClient,
  QueryClientProvider,
  useMutation,
  useQueries,
  useQuery,
} from '@tanstack/react-query';

type PortalType = 'admin' | 'staff';

type AppUser = {
  uuid?: string;
  name?: string;
  email?: string;
  phone?: string;
  role?: string;
  is_platform_admin?: boolean;
};

type QueryMap = Record<string, string | number | boolean | undefined | null>;
type JsonMap = Record<string, unknown>;

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'https://api.progarage.cloud/api';
const ENV_PORTAL = import.meta.env.VITE_PORTAL;
const ACTIVE_PORTAL: PortalType = ENV_PORTAL === 'admin' || window.location.hostname.startsWith('admin.')
  ? 'admin'
  : 'staff';
const TOKEN_KEY = ACTIVE_PORTAL === 'admin' ? 'pg_admin_token' : 'pg_staff_token';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

class ApiError extends Error {
  public status: number;

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

async function apiRequest<T = unknown>(
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

function asData<T>(payload: unknown): T {
  if (payload && typeof payload === 'object' && 'data' in (payload as JsonMap)) {
    return (payload as { data: T }).data;
  }
  return payload as T;
}

function asList<T>(payload: unknown): { items: T[]; meta?: JsonMap } {
  if (Array.isArray(payload)) {
    return { items: payload as T[] };
  }
  if (!payload || typeof payload !== 'object') {
    return { items: [] };
  }
  const map = payload as JsonMap;
  if (Array.isArray(map.data)) {
    const meta = (map.meta as JsonMap | undefined) ?? undefined;
    return { items: map.data as T[], meta };
  }
  const inner = map.data as JsonMap | undefined;
  if (inner && Array.isArray(inner.items)) {
    const meta = (inner.meta as JsonMap | undefined) ?? undefined;
    return { items: inner.items as T[], meta };
  }
  return { items: [] };
}

function extractToken(payload: unknown): string {
  if (!payload || typeof payload !== 'object') {
    return '';
  }
  const map = payload as JsonMap;
  if (typeof map.token === 'string') {
    return map.token;
  }
  const data = map.data as JsonMap | undefined;
  return (typeof data?.token === 'string' ? data.token : '') || '';
}

function extractUser(payload: unknown): AppUser {
  const data = asData<JsonMap | AppUser>(payload);
  if (data && typeof data === 'object' && 'user' in (data as JsonMap)) {
    return ((data as JsonMap).user as AppUser) ?? {};
  }
  return (data as AppUser) ?? {};
}

function tenantLabel(tenant: JsonMap): string {
  return String(tenant.business_name ?? tenant.name ?? '-');
}

function tenantOwner(tenant: JsonMap): string {
  const owner = tenant.owner as JsonMap | undefined;
  return String(owner?.phone ?? owner?.name ?? tenant.owner_name ?? tenant.owner_email ?? '-');
}

function tenantPlan(tenant: JsonMap): string {
  const sub = tenant.subscription as JsonMap | undefined;
  return String(sub?.plan_name ?? tenant.plan_name ?? '-');
}

function normalizeStatus(value: string | undefined): string {
  if (!value) {
    return 'unknown';
  }
  return value.replace(/_/g, ' ');
}

const statusPalette: Record<string, string> = {
  draft: 'status-draft',
  intake_inspection: 'status-intake',
  estimate_pending: 'status-estimate',
  estimate_approved: 'status-approved',
  in_progress: 'status-progress',
  qc_pending: 'status-qc',
  ready_for_delivery: 'status-ready',
  delivered: 'status-delivered',
  cancelled: 'status-cancelled',
  on_hold: 'status-hold',
  active: 'status-ready',
  trial: 'status-estimate',
  suspended: 'status-cancelled',
  churned: 'status-draft',
};

function Button(props: {
  children: ReactNode;
  type?: 'button' | 'submit';
  variant?: 'primary' | 'outline' | 'ghost';
  onClick?: () => void;
  disabled?: boolean;
}) {
  const variant = props.variant ?? 'primary';
  return (
    <button
      type={props.type ?? 'button'}
      disabled={props.disabled}
      onClick={props.onClick}
      className={`gf-btn gf-btn-${variant}`}
    >
      {props.children}
    </button>
  );
}

function Card(props: { children: ReactNode; className?: string }) {
  return <section className={`gf-card ${props.className ?? ''}`}>{props.children}</section>;
}

function KPICard(props: { label: string; value: string | number; helper?: string }) {
  return (
    <Card>
      <div className="kpi-label">{props.label}</div>
      <div className="kpi-value">{props.value}</div>
      <div className="kpi-helper">{props.helper ?? ''}</div>
    </Card>
  );
}

function StatusBadge(props: { status?: string }) {
  const key = props.status ?? 'draft';
  const cls = statusPalette[key] ?? 'status-draft';
  return <span className={`status-badge ${cls}`}>{normalizeStatus(key)}</span>;
}

function THead(props: { children: ReactNode }) {
  return <thead className="gf-table-head">{props.children}</thead>;
}
function TRow(props: { children: ReactNode }) {
  return <tr>{props.children}</tr>;
}
function TH(props: { children: ReactNode }) {
  return <th>{props.children}</th>;
}
function TD(props: { children: ReactNode }) {
  return <td>{props.children}</td>;
}

function PinInput(props: { value: string; onChange: (v: string) => void; length?: number }) {
  const length = props.length ?? 6;
  const boxes = Array.from({ length }, (_, i) => props.value[i] ?? '');
  return (
    <div className="pin-grid">
      {boxes.map((digit, idx) => (
        <input
          key={idx}
          className="pin-box"
          inputMode="numeric"
          maxLength={1}
          value={digit}
          onChange={(event) => {
            const next = event.target.value.replace(/\D/g, '').slice(-1);
            const list = boxes.slice();
            list[idx] = next;
            props.onChange(list.join(''));
            if (next) {
              const element = document.querySelector<HTMLInputElement>(`#pin-${idx + 1}`);
              element?.focus();
            }
          }}
          onKeyDown={(event) => {
            if (event.key === 'Backspace' && !digit && idx > 0) {
              const element = document.querySelector<HTMLInputElement>(`#pin-${idx - 1}`);
              element?.focus();
            }
          }}
          id={`pin-${idx}`}
        />
      ))}
    </div>
  );
}

function useAuth() {
  const [token, setToken] = useState<string>(() => localStorage.getItem(TOKEN_KEY) ?? '');

  const meQuery = useQuery({
    queryKey: ['auth-me', token, ACTIVE_PORTAL],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/auth/me', { token });
      return extractUser(payload);
    },
  });

  useEffect(() => {
    if (!meQuery.data) {
      return;
    }
    const isPlatformAdmin = Boolean(meQuery.data.is_platform_admin);
    const portalMismatch =
      (ACTIVE_PORTAL === 'admin' && !isPlatformAdmin) ||
      (ACTIVE_PORTAL === 'staff' && isPlatformAdmin);
    if (portalMismatch) {
      localStorage.removeItem(TOKEN_KEY);
      setToken('');
    }
  }, [meQuery.data]);

  const loginMutation = useMutation({
    mutationFn: async (params: { email: string; pin: string }) => {
      const payload = await apiRequest('/auth/staff/login', {
        method: 'POST',
        body: { login: params.email, pin: params.pin },
      });
      const loginToken = extractToken(payload);
      const user = extractUser(payload);
      const isPlatformAdmin = Boolean(user.is_platform_admin);
      if (!loginToken) {
        throw new ApiError('Token missing in login response', 500);
      }
      if (ACTIVE_PORTAL === 'admin' && !isPlatformAdmin) {
        throw new ApiError('This account is not allowed on admin portal', 403);
      }
      if (ACTIVE_PORTAL === 'staff' && isPlatformAdmin) {
        throw new ApiError('Platform admin accounts must sign in at admin subdomain', 403);
      }
      localStorage.setItem(TOKEN_KEY, loginToken);
      setToken(loginToken);
      queryClient.invalidateQueries({ queryKey: ['auth-me'] });
      return user;
    },
  });

  const logoutMutation = useMutation({
    mutationFn: async () => {
      if (token) {
        await apiRequest('/auth/logout', { method: 'POST', token });
      }
      localStorage.removeItem(TOKEN_KEY);
      setToken('');
      queryClient.clear();
    },
  });

  return {
    token,
    user: meQuery.data,
    isReady: !meQuery.isLoading,
    isAuthenticated: token.length > 0,
    loginMutation,
    logoutMutation,
    refreshMe: meQuery.refetch,
  };
}

function AppShell(props: {
  title: string;
  children: ReactNode;
  userName?: string;
  onLogout: () => void;
}) {
  const isAdmin = ACTIVE_PORTAL === 'admin';
  const staffNav = [
    { to: '/', label: 'Dashboard' },
    { to: '/jobs', label: 'Jobs' },
    { to: '/customers', label: 'Customers' },
    { to: '/inventory', label: 'Inventory' },
    { to: '/billing', label: 'Billing' },
    { to: '/reports', label: 'Reports' },
    { to: '/settings', label: 'Settings' },
    { to: '/notifications', label: 'Notifications' },
  ];
  const adminNav = [
    { to: '/', label: 'Dashboard' },
    { to: '/tenants', label: 'Tenants' },
    { to: '/plans', label: 'Plans' },
    { to: '/subscriptions', label: 'Subscriptions' },
    { to: '/settings', label: 'Settings' },
    { to: '/admins', label: 'Admins' },
    { to: '/audit', label: 'Audit' },
    { to: '/support', label: 'Support' },
  ];
  const items = isAdmin ? adminNav : staffNav;

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <h1>GarageFlow</h1>
          <p>{isAdmin ? 'Platform Admin' : 'Garage Portal'}</p>
        </div>
        <nav className="sidebar-nav">
          {items.map((item) => (
            <NavLink
              to={item.to}
              key={item.to}
              end={item.to === '/'}
              className={({ isActive }) => (isActive ? 'nav-item active' : 'nav-item')}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <button className="sidebar-logout" type="button" onClick={props.onLogout}>
          Logout
        </button>
      </aside>
      <main className="page-wrap">
        <header className="page-header">
          <div>
            <h2>{props.title}</h2>
            <p>{isAdmin ? 'Super admin workspace' : 'Garage operations workspace'}</p>
          </div>
          <div className="header-user">{props.userName ?? 'User'}</div>
        </header>
        <section className="page-content">{props.children}</section>
      </main>
    </div>
  );
}

function usePaginatedList(path: string, token: string, query?: QueryMap) {
  return useQuery({
    queryKey: ['list', path, query, token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest(path, { token, query });
      return asList<JsonMap>(payload);
    },
  });
}

function RequireAuth(props: { auth: ReturnType<typeof useAuth> }) {
  if (!props.auth.isReady) {
    return <div className="center-state">Checking session...</div>;
  }
  if (!props.auth.isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return <Outlet />;
}

function LoginPage(props: { auth: ReturnType<typeof useAuth> }) {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [pin, setPin] = useState('');
  const isAdmin = ACTIVE_PORTAL === 'admin';

  useEffect(() => {
    if (props.auth.isAuthenticated) {
      navigate('/', { replace: true });
    }
  }, [props.auth.isAuthenticated, navigate]);

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    await props.auth.loginMutation.mutateAsync({ email, pin });
    navigate('/', { replace: true });
  };

  return (
    <div className="auth-page">
      <Card className="auth-card">
        <h1>{isAdmin ? 'Platform Admin Login' : 'Garage Staff Login'}</h1>
        <p>{isAdmin ? 'Use admin account with platform access.' : 'Sign in with staff credentials and PIN.'}</p>
        <form className="auth-form" onSubmit={onSubmit}>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder="name@garage.com"
            required
          />
          <label htmlFor="pin">PIN</label>
          <PinInput value={pin} onChange={setPin} />
          {props.auth.loginMutation.error ? (
            <div className="error-text">{(props.auth.loginMutation.error as Error).message}</div>
          ) : null}
          <Button type="submit" disabled={props.auth.loginMutation.isPending || pin.length < 4}>
            {props.auth.loginMutation.isPending ? 'Signing in...' : 'Sign in'}
          </Button>
        </form>
      </Card>
    </div>
  );
}

function StaffDashboard(props: { token: string; userName?: string; onLogout: () => void }) {
  const summaryQuery = useQuery({
    queryKey: ['staff-dashboard', props.token],
    queryFn: () => apiRequest('/dashboard/summary', { token: props.token }),
  });
  const summary = asData<JsonMap>(summaryQuery.data ?? {});
  const activeJobs = (summary.active_jobs as JsonMap[] | undefined) ?? [];
  const bays = (summary.service_bays as JsonMap[] | undefined) ?? [];

  return (
    <AppShell title="Dashboard" userName={props.userName} onLogout={props.onLogout}>
      <div className="kpi-grid">
        <KPICard label="Open Jobs" value={String(summary.open_jobs ?? 0)} />
        <KPICard label="Revenue Today" value={`₹${summary.revenue_today ?? 0}`} />
        <KPICard label="Pending Invoices" value={String(summary.pending_invoices ?? 0)} />
        <KPICard label="Low Stock Items" value={String(summary.low_stock_count ?? 0)} />
      </div>
      <div className="split-grid">
        <Card>
          <h3>Service Bays</h3>
          <div className="stack">
            {bays.length === 0 ? <p className="muted">No bay status available.</p> : null}
            {bays.map((bay) => (
              <div key={String(bay.uuid ?? bay.name)} className="line-item">
                <strong>{String(bay.name ?? 'Bay')}</strong>
                <StatusBadge status={String(bay.status ?? 'draft')} />
              </div>
            ))}
          </div>
        </Card>
        <Card>
          <h3>Active Jobs</h3>
          <table className="gf-table">
            <THead>
              <TRow>
                <TH>Job</TH>
                <TH>Customer</TH>
                <TH>Status</TH>
              </TRow>
            </THead>
            <tbody>
              {activeJobs.slice(0, 8).map((job) => (
                <TRow key={String(job.uuid ?? job.id)}>
                  <TD>
                    <Link to={`/jobs/${String(job.uuid ?? '')}`}>{String(job.job_number ?? job.uuid ?? 'Job')}</Link>
                  </TD>
                  <TD>{String(job.customer_name ?? '-')}</TD>
                  <TD>
                    <StatusBadge status={String(job.status ?? 'draft')} />
                  </TD>
                </TRow>
              ))}
            </tbody>
          </table>
        </Card>
      </div>
    </AppShell>
  );
}

function JobsListPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [page, setPage] = useState(1);
  const jobsQuery = usePaginatedList('/jobs', props.token, { page, search, status });

  return (
    <AppShell title="Jobs" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <div className="toolbar">
          <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search jobs" />
          <input value={status} onChange={(event) => setStatus(event.target.value)} placeholder="Status filter" />
          <Link to="/jobs/new" className="gf-link-button">
            New Job
          </Link>
        </div>
        <table className="gf-table">
          <THead>
            <TRow>
              <TH>Job #</TH>
              <TH>Customer</TH>
              <TH>Vehicle</TH>
              <TH>Status</TH>
            </TRow>
          </THead>
          <tbody>
            {jobsQuery.data?.items.map((job) => (
              <TRow key={String(job.uuid ?? job.id)}>
                <TD>
                  <Link to={`/jobs/${String(job.uuid ?? '')}`}>{String(job.job_number ?? job.uuid ?? 'Job')}</Link>
                </TD>
                <TD>{String(job.customer_name ?? '-')}</TD>
                <TD>{String(job.vehicle_registration ?? '-')}</TD>
                <TD>
                  <StatusBadge status={String(job.status ?? 'draft')} />
                </TD>
              </TRow>
            ))}
          </tbody>
        </table>
        <div className="pager">
          <Button variant="outline" onClick={() => setPage((p) => Math.max(1, p - 1))}>
            Previous
          </Button>
          <span>Page {page}</span>
          <Button variant="outline" onClick={() => setPage((p) => p + 1)}>
            Next
          </Button>
        </div>
      </Card>
    </AppShell>
  );
}

function JobDetailPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const { uuid = '' } = useParams();
  const jobQuery = useQuery({
    queryKey: ['job-detail', uuid, props.token],
    enabled: uuid.length > 0,
    queryFn: () => apiRequest(`/jobs/${uuid}`, { token: props.token }),
  });
  const job = asData<JsonMap>(jobQuery.data ?? {});
  return (
    <AppShell title="Job Detail" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <h3>{String(job.job_number ?? uuid)}</h3>
        <div className="detail-grid">
          <div>
            <label>Status</label>
            <StatusBadge status={String(job.status ?? 'draft')} />
          </div>
          <div>
            <label>Customer</label>
            <p>{String(job.customer_name ?? '-')}</p>
          </div>
          <div>
            <label>Vehicle</label>
            <p>{String(job.vehicle_registration ?? '-')}</p>
          </div>
          <div>
            <label>Total</label>
            <p>₹{String(job.total_amount ?? 0)}</p>
          </div>
        </div>
      </Card>
    </AppShell>
  );
}

function NewJobPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const navigate = useNavigate();
  const [form, setForm] = useState({
    customer_uuid: '',
    vehicle_uuid: '',
    concern: '',
    notes: '',
  });
  const createMutation = useMutation({
    mutationFn: async () => {
      await apiRequest('/jobs', {
        method: 'POST',
        token: props.token,
        body: form,
      });
    },
    onSuccess: () => navigate('/jobs'),
  });

  return (
    <AppShell title="Create Job" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <form
          className="stack form-grid"
          onSubmit={(event) => {
            event.preventDefault();
            createMutation.mutate();
          }}
        >
          <label htmlFor="customer_uuid">Customer UUID</label>
          <input
            id="customer_uuid"
            value={form.customer_uuid}
            onChange={(event) => setForm((prev) => ({ ...prev, customer_uuid: event.target.value }))}
            required
          />
          <label htmlFor="vehicle_uuid">Vehicle UUID</label>
          <input
            id="vehicle_uuid"
            value={form.vehicle_uuid}
            onChange={(event) => setForm((prev) => ({ ...prev, vehicle_uuid: event.target.value }))}
            required
          />
          <label htmlFor="concern">Concern</label>
          <input
            id="concern"
            value={form.concern}
            onChange={(event) => setForm((prev) => ({ ...prev, concern: event.target.value }))}
            required
          />
          <label htmlFor="notes">Notes</label>
          <textarea
            id="notes"
            value={form.notes}
            onChange={(event) => setForm((prev) => ({ ...prev, notes: event.target.value }))}
          />
          {createMutation.error ? <p className="error-text">{(createMutation.error as Error).message}</p> : null}
          <Button type="submit" disabled={createMutation.isPending}>
            {createMutation.isPending ? 'Creating...' : 'Create Job'}
          </Button>
        </form>
      </Card>
    </AppShell>
  );
}

function CustomersListPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const query = usePaginatedList('/customers', props.token);
  return (
    <AppShell title="Customers" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <table className="gf-table">
          <THead>
            <TRow>
              <TH>Name</TH>
              <TH>Phone</TH>
              <TH>Email</TH>
            </TRow>
          </THead>
          <tbody>
            {query.data?.items.map((item) => (
              <TRow key={String(item.uuid ?? item.id)}>
                <TD>
                  <Link to={`/customers/${String(item.uuid ?? '')}`}>{String(item.name ?? '-')}</Link>
                </TD>
                <TD>{String(item.phone ?? '-')}</TD>
                <TD>{String(item.email ?? '-')}</TD>
              </TRow>
            ))}
          </tbody>
        </table>
      </Card>
    </AppShell>
  );
}

function CustomerDetailPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const { uuid = '' } = useParams();
  const detailQuery = useQuery({
    queryKey: ['customer-detail', uuid, props.token],
    enabled: uuid.length > 0,
    queryFn: () => apiRequest(`/customers/${uuid}`, { token: props.token }),
  });
  const customer = asData<JsonMap>(detailQuery.data ?? {});
  return (
    <AppShell title="Customer Detail" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <h3>{String(customer.name ?? 'Customer')}</h3>
        <p>Phone: {String(customer.phone ?? '-')}</p>
        <p>Email: {String(customer.email ?? '-')}</p>
      </Card>
    </AppShell>
  );
}

function InventoryPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const query = usePaginatedList('/inventory', props.token);
  return (
    <AppShell title="Inventory" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <table className="gf-table">
          <THead>
            <TRow>
              <TH>Part</TH>
              <TH>SKU</TH>
              <TH>Stock</TH>
            </TRow>
          </THead>
          <tbody>
            {query.data?.items.map((item) => (
              <TRow key={String(item.uuid ?? item.id)}>
                <TD>{String(item.name ?? '-')}</TD>
                <TD>{String(item.sku ?? '-')}</TD>
                <TD>{String(item.stock ?? '-')}</TD>
              </TRow>
            ))}
          </tbody>
        </table>
      </Card>
    </AppShell>
  );
}

function BillingListPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const query = usePaginatedList('/invoices', props.token);
  return (
    <AppShell title="Billing" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <table className="gf-table">
          <THead>
            <TRow>
              <TH>Invoice</TH>
              <TH>Customer</TH>
              <TH>Status</TH>
              <TH>Total</TH>
            </TRow>
          </THead>
          <tbody>
            {query.data?.items.map((item) => (
              <TRow key={String(item.uuid ?? item.id)}>
                <TD>
                  <Link to={`/billing/${String(item.uuid ?? '')}`}>{String(item.invoice_number ?? item.number ?? item.uuid ?? '-')}</Link>
                </TD>
                <TD>{String(item.customer_name ?? '-')}</TD>
                <TD>
                  <StatusBadge status={String(item.status ?? 'draft')} />
                </TD>
                <TD>₹{String(item.total ?? 0)}</TD>
              </TRow>
            ))}
          </tbody>
        </table>
      </Card>
    </AppShell>
  );
}

function BillingDetailPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const { uuid = '' } = useParams();
  const detailQuery = useQuery({
    queryKey: ['billing-detail', uuid, props.token],
    enabled: uuid.length > 0,
    queryFn: () => apiRequest(`/invoices/${uuid}`, { token: props.token }),
  });
  const invoice = asData<JsonMap>(detailQuery.data ?? {});
  return (
    <AppShell title="Invoice Detail" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <h3>Invoice {String(invoice.number ?? uuid)}</h3>
        <p>Status: {String(invoice.status ?? '-')}</p>
        <p>Total: ₹{String(invoice.total ?? 0)}</p>
        <p>Due date: {String(invoice.due_date ?? '-')}</p>
      </Card>
    </AppShell>
  );
}

function ReportsPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const [summary, jobs, inventory] = useQueries({
    queries: [
      { queryKey: ['report-summary', props.token], queryFn: () => apiRequest('/dashboard/summary', { token: props.token }) },
      { queryKey: ['report-jobs', props.token], queryFn: () => apiRequest('/jobs', { token: props.token }) },
      { queryKey: ['report-inventory', props.token], queryFn: () => apiRequest('/inventory', { token: props.token }) },
    ],
  });
  const reportSummary = asData<JsonMap>(summary.data ?? {});
  const jobsList = asList<JsonMap>(jobs.data).items;
  const inventoryList = asList<JsonMap>(inventory.data).items;
  const lowStock = inventoryList.filter((item) => Number(item.stock ?? 0) <= Number(item.reorder_level ?? 3)).length;

  return (
    <AppShell title="Reports" userName={props.userName} onLogout={props.onLogout}>
      <div className="kpi-grid">
        <KPICard label="Jobs Count" value={jobsList.length} />
        <KPICard label="Low Stock Alerts" value={lowStock} />
        <KPICard label="Revenue (today)" value={`₹${String(reportSummary.revenue_today ?? 0)}`} />
        <KPICard label="Pending Invoices" value={String(reportSummary.pending_invoices ?? 0)} />
      </div>
    </AppShell>
  );
}

function StaffSettingsPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const [tenantQuery, staffQuery] = useQueries({
    queries: [
      { queryKey: ['tenant-profile', props.token], queryFn: () => apiRequest('/tenant/profile', { token: props.token }) },
      { queryKey: ['staff-list', props.token], queryFn: () => apiRequest('/staff', { token: props.token }) },
    ],
  });
  const tenant = asData<JsonMap>(tenantQuery.data ?? {});
  const staff = asList<JsonMap>(staffQuery.data).items;
  return (
    <AppShell title="Settings" userName={props.userName} onLogout={props.onLogout}>
      <div className="split-grid">
        <Card>
          <h3>Tenant Profile</h3>
          <p>Name: {String(tenant.business_name ?? tenant.name ?? '-')}</p>
          <p>Phone: {String(tenant.phone ?? '-')}</p>
          <p>Address: {String(tenant.address ?? '-')}</p>
        </Card>
        <Card>
          <h3>Staff List</h3>
          <ul className="stack">
            {staff.map((member) => (
              <li key={String(member.uuid ?? member.id)}>
                {String(member.first_name ?? '')} {String(member.last_name ?? '')} ({String(member.role ?? '-')})
              </li>
            ))}
          </ul>
        </Card>
      </div>
    </AppShell>
  );
}

function NotificationsPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const query = usePaginatedList('/notifications', props.token);
  return (
    <AppShell title="Notifications" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <ul className="stack">
          {query.data?.items.map((item) => (
            <li key={String(item.uuid ?? item.id)}>
              <strong>{String(item.title ?? 'Notification')}</strong>
              <p>{String(item.message ?? '-')}</p>
            </li>
          ))}
        </ul>
      </Card>
    </AppShell>
  );
}

function AdminDashboardPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const tenantsQuery = usePaginatedList('/platform/tenants', props.token);
  const tenants = tenantsQuery.data?.items ?? [];
  const active = tenants.filter((t) => String(t.status ?? '').toLowerCase() === 'active').length;
  const trial = tenants.filter((t) => String(t.status ?? '').toLowerCase() === 'trial').length;
  const suspended = tenants.filter((t) => String(t.status ?? '').toLowerCase() === 'suspended').length;
  return (
    <AppShell title="Platform Dashboard" userName={props.userName} onLogout={props.onLogout}>
      <div className="kpi-grid">
        <KPICard label="Total Tenants" value={tenants.length} />
        <KPICard label="Active" value={active} />
        <KPICard label="Trial" value={trial} />
        <KPICard label="Suspended" value={suspended} />
      </div>
    </AppShell>
  );
}

function TenantsPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const query = usePaginatedList('/platform/tenants', props.token);
  return (
    <AppShell title="Tenants" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <div className="toolbar">
          <Link to="/tenants/new" className="gf-link-button">
            Create Tenant
          </Link>
        </div>
        <table className="gf-table">
          <THead>
            <TRow>
              <TH>Name</TH>
              <TH>Owner</TH>
              <TH>Plan</TH>
              <TH>Status</TH>
            </TRow>
          </THead>
          <tbody>
            {query.data?.items.map((tenant) => (
              <TRow key={String(tenant.uuid ?? tenant.id)}>
                <TD>
                  <Link to={`/tenants/${String(tenant.uuid ?? '')}`}>{tenantLabel(tenant)}</Link>
                </TD>
                <TD>{tenantOwner(tenant)}</TD>
                <TD>{tenantPlan(tenant)}</TD>
                <TD>
                  <StatusBadge status={String(tenant.status ?? 'active')} />
                </TD>
              </TRow>
            ))}
          </tbody>
        </table>
      </Card>
    </AppShell>
  );
}

function NewTenantPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const navigate = useNavigate();
  const [payload, setPayload] = useState({
    business_name: '',
    first_name: '',
    last_name: '',
    email: '',
    phone: '',
    plan_slug: 'starter',
  });
  const createMutation = useMutation({
    mutationFn: () =>
      apiRequest('/platform/tenants', {
        method: 'POST',
        token: props.token,
        body: {
          business_name: payload.business_name,
          first_name: payload.first_name,
          last_name: payload.last_name || undefined,
          email: payload.email || undefined,
          phone: payload.phone,
          plan_slug: payload.plan_slug,
        },
      }),
    onSuccess: () => navigate('/tenants'),
  });
  return (
    <AppShell title="Create Tenant" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <form
          className="stack form-grid"
          onSubmit={(event) => {
            event.preventDefault();
            createMutation.mutate();
          }}
        >
          {Object.keys(payload).map((key) => (
            <div key={key} className="stack">
              <label htmlFor={key}>{key.replace(/_/g, ' ')}</label>
              <input
                id={key}
                value={payload[key as keyof typeof payload]}
                onChange={(event) =>
                  setPayload((prev) => ({ ...prev, [key]: event.target.value }))
                }
                required
              />
            </div>
          ))}
          {createMutation.error ? <p className="error-text">{(createMutation.error as Error).message}</p> : null}
          <Button type="submit">Create Tenant</Button>
        </form>
      </Card>
    </AppShell>
  );
}

function TenantDetailPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const { uuid = '' } = useParams();
  const query = useQuery({
    queryKey: ['tenant-detail', uuid, props.token],
    enabled: uuid.length > 0,
    queryFn: () => apiRequest(`/platform/tenants/${uuid}`, { token: props.token }),
  });
  const tenant = asData<JsonMap>(query.data ?? {});
  return (
    <AppShell title="Tenant Detail" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <h3>{tenantLabel(tenant)}</h3>
        <p>UUID: {uuid}</p>
        <p>Status: {String(tenant.status ?? '-')}</p>
        <p>Plan: {tenantPlan(tenant)}</p>
        <p>Owner: {tenantOwner(tenant)}</p>
      </Card>
    </AppShell>
  );
}

function PlansPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const query = usePaginatedList('/platform/plans', props.token);
  return (
    <AppShell title="Plans" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <table className="gf-table">
          <THead>
            <TRow>
              <TH>Plan</TH>
              <TH>Price</TH>
              <TH>Billing Cycle</TH>
            </TRow>
          </THead>
          <tbody>
            {query.data?.items.map((plan) => (
              <TRow key={String(plan.uuid ?? plan.id)}>
                <TD>{String(plan.name ?? '-')}</TD>
                <TD>₹{String(plan.price ?? 0)}</TD>
                <TD>{String(plan.billing_cycle ?? plan.interval ?? 'monthly')}</TD>
              </TRow>
            ))}
          </tbody>
        </table>
      </Card>
    </AppShell>
  );
}

function SubscriptionsPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const query = usePaginatedList('/platform/tenants', props.token);
  const subscriptions = (query.data?.items ?? []).filter((tenant) => tenant.subscription);
  return (
    <AppShell title="Subscriptions" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <table className="gf-table">
          <THead>
            <TRow>
              <TH>Tenant</TH>
              <TH>Plan</TH>
              <TH>Renewal</TH>
            </TRow>
          </THead>
          <tbody>
            {subscriptions.map((tenant) => {
              const sub = tenant.subscription as JsonMap;
              return (
                <TRow key={String(tenant.uuid ?? tenant.id)}>
                  <TD>{tenantLabel(tenant)}</TD>
                  <TD>{tenantPlan(tenant)}</TD>
                  <TD>{String(sub.current_period_end ?? sub.renewal_date ?? '-')}</TD>
                </TRow>
              );
            })}
          </tbody>
        </table>
      </Card>
    </AppShell>
  );
}

function AdminSettingsPage(props: { userName?: string; onLogout: () => void }) {
  const [message, setMessage] = useState(() => localStorage.getItem('pg_admin_maintenance_message') ?? '');
  const [saved, setSaved] = useState(false);

  return (
    <AppShell title="Platform Settings" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        <h3>Maintenance Message (local)</h3>
        <textarea value={message} onChange={(event) => setMessage(event.target.value)} />
        <div className="toolbar">
          <Button
            onClick={() => {
              localStorage.setItem('pg_admin_maintenance_message', message);
              setSaved(true);
              setTimeout(() => setSaved(false), 1500);
            }}
          >
            Save message
          </Button>
          {saved ? <span className="muted">Saved</span> : null}
        </div>
      </Card>
    </AppShell>
  );
}

function AdminsPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const query = useQuery({
    queryKey: ['platform-admins', props.token],
    queryFn: () => apiRequest('/platform/users', { token: props.token }),
  });
  const data = asList<JsonMap>(query.data).items;
  const hasData = data.length > 0;
  return (
    <AppShell title="Platform Admins" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        {!hasData ? (
          <p className="muted">
            No dedicated admin API response found. Seed admin: admin@progarage.cloud
          </p>
        ) : null}
        <ul className="stack">
          {data.map((admin) => (
            <li key={String(admin.uuid ?? admin.id)}>{String(admin.email ?? admin.name ?? '-')}</li>
          ))}
        </ul>
      </Card>
    </AppShell>
  );
}

function AuditPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const query = usePaginatedList('/audit-logs', props.token);
  const accessDenied = query.error instanceof ApiError && query.error.status === 403;
  return (
    <AppShell title="Audit Log" userName={props.userName} onLogout={props.onLogout}>
      <Card>
        {accessDenied ? (
          <p className="muted">Audit logs are tenant-scoped for this account.</p>
        ) : (
          <ul className="stack">
            {query.data?.items.map((entry) => (
              <li key={String(entry.uuid ?? entry.id)}>
                {String(entry.action ?? entry.event ?? 'event')} - {String(entry.created_at ?? '-')}
              </li>
            ))}
          </ul>
        )}
      </Card>
    </AppShell>
  );
}

function SupportPage(props: { token: string; userName?: string; onLogout: () => void }) {
  const [tenantUuid, setTenantUuid] = useState('');
  const healthQuery = useQuery({
    queryKey: ['health-check'],
    queryFn: () => apiRequest('/health'),
  });
  const storageQuery = useQuery({
    queryKey: ['platform-storage', props.token],
    enabled: props.token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/platform/storage/files', {
        token: props.token,
        query: { disk: 's3', prefix: 'tenants/' },
      });
      return asList<JsonMap>(payload);
    },
  });
  const resetMutation = useMutation({
    mutationFn: () =>
      apiRequest(`/platform/tenants/${tenantUuid}/reset-data`, {
        method: 'POST',
        token: props.token,
        body: { reset_onboarding: true },
      }),
  });
  return (
    <AppShell title="Support Tools" userName={props.userName} onLogout={props.onLogout}>
      <div className="split-grid">
        <Card>
          <h3>Health Check</h3>
          <pre>{JSON.stringify(healthQuery.data ?? { status: 'loading' }, null, 2)}</pre>
        </Card>
        <Card>
          <h3>Storage Browser</h3>
          <ul className="stack">
            {storageQuery.data?.items.slice(0, 20).map((entry) => (
              <li key={String(entry.path ?? entry.key ?? entry.uuid)}>{String(entry.path ?? entry.key ?? '-')}</li>
            ))}
          </ul>
        </Card>
      </div>
      <Card>
        <h3>Reset Tenant</h3>
        <div className="toolbar">
          <input
            value={tenantUuid}
            onChange={(event) => setTenantUuid(event.target.value)}
            placeholder="Tenant UUID"
          />
          <Button onClick={() => resetMutation.mutate()} disabled={!tenantUuid}>
            Run reset
          </Button>
        </div>
        {resetMutation.error ? <p className="error-text">{(resetMutation.error as Error).message}</p> : null}
      </Card>
    </AppShell>
  );
}

function StaffRoutes(props: { auth: ReturnType<typeof useAuth> }) {
  const logout = () => props.auth.logoutMutation.mutate();
  return (
    <Routes>
      <Route path="/login" element={<LoginPage auth={props.auth} />} />
      <Route element={<RequireAuth auth={props.auth} />}>
        <Route path="/" element={<StaffDashboard token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/jobs" element={<JobsListPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/jobs/new" element={<NewJobPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/jobs/:uuid" element={<JobDetailPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/customers" element={<CustomersListPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/customers/:uuid" element={<CustomerDetailPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/inventory" element={<InventoryPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/billing" element={<BillingListPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/billing/:uuid" element={<BillingDetailPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/reports" element={<ReportsPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/settings" element={<StaffSettingsPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/notifications" element={<NotificationsPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

function AdminRoutes(props: { auth: ReturnType<typeof useAuth> }) {
  const logout = () => props.auth.logoutMutation.mutate();
  return (
    <Routes>
      <Route path="/login" element={<LoginPage auth={props.auth} />} />
      <Route element={<RequireAuth auth={props.auth} />}>
        <Route path="/" element={<AdminDashboardPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/tenants" element={<TenantsPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/tenants/new" element={<NewTenantPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/tenants/:uuid" element={<TenantDetailPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/plans" element={<PlansPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/subscriptions" element={<SubscriptionsPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/settings" element={<AdminSettingsPage userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/admins" element={<AdminsPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/audit" element={<AuditPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
        <Route path="/support" element={<SupportPage token={props.auth.token} userName={props.auth.user?.name} onLogout={logout} />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

function RootRouter() {
  const auth = useAuth();
  const routes = useMemo(() => {
    if (ACTIVE_PORTAL === 'admin') {
      return <AdminRoutes auth={auth} />;
    }
    return <StaffRoutes auth={auth} />;
  }, [auth]);
  return <BrowserRouter>{routes}</BrowserRouter>;
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <RootRouter />
    </QueryClientProvider>
  );
}
