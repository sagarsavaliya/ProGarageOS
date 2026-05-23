import { useEffect, useState } from 'react';
import { api, getToken, loginStaff, Plan, Tenant, PlatformUser } from './api';

type Tab = 'tenants' | 'plans' | 'storage';

export default function App() {
  const [token, setTokenState] = useState(getToken());
  const [tab, setTab] = useState<Tab>('tenants');
  const [login, setLogin] = useState('admin@progarage.cloud');
  const [pin, setPin] = useState('');
  const [error, setError] = useState('');

  if (!token) {
    return (
      <div className="login-wrap card">
        <h2>Pro Garage Platform Admin</h2>
        <p style={{ color: '#8891a0', fontSize: 14 }}>Super-admin access only</p>
        <label>Email or phone</label>
        <input value={login} onChange={(e) => setLogin(e.target.value)} />
        <label>6-digit PIN</label>
        <input value={pin} onChange={(e) => setPin(e.target.value)} maxLength={6} />
        {error && <p className="error">{error}</p>}
        <button
          className="btn"
          type="button"
          onClick={async () => {
            try {
              setError('');
              await loginStaff(login, pin);
              setTokenState(getToken());
            } catch (e) {
              setError(e instanceof Error ? e.message : 'Login failed');
            }
          }}
        >
          Sign in
        </button>
      </div>
    );
  }

  return (
    <div className="layout">
      <aside className="sidebar">
        <h1>Platform Admin</h1>
        <button type="button" className={tab === 'tenants' ? 'active' : ''} onClick={() => setTab('tenants')}>
          Garages
        </button>
        <button type="button" className={tab === 'plans' ? 'active' : ''} onClick={() => setTab('plans')}>
          Subscription plans
        </button>
        <button type="button" className={tab === 'storage' ? 'active' : ''} onClick={() => setTab('storage')}>
          Storage files
        </button>
        <button
          type="button"
          style={{ marginTop: 24 }}
          onClick={() => {
            localStorage.removeItem('pg_admin_token');
            setTokenState(null);
          }}
        >
          Log out
        </button>
      </aside>
      <main className="main">
        {tab === 'tenants' && <TenantsPanel />}
        {tab === 'plans' && <PlansPanel />}
        {tab === 'storage' && <StoragePanel />}
      </main>
    </div>
  );
}

function TenantsPanel() {
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [search, setSearch] = useState('');
  const [error, setError] = useState('');
  const [selected, setSelected] = useState<Tenant | null>(null);
  const [users, setUsers] = useState<PlatformUser[]>([]);
  const [form, setForm] = useState({
    business_name: '',
    first_name: '',
    phone: '',
    plan_slug: 'starter',
    status: 'active',
  });

  const load = async () => {
    try {
      setError('');
      const res = await api.tenants(search ? `search=${encodeURIComponent(search)}` : undefined);
      setTenants(res.data);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    }
  };

  useEffect(() => {
    load();
  }, []);

  const openTenant = async (t: Tenant) => {
    setSelected(t);
    const u = await api.users(t.uuid);
    setUsers(u.data);
  };

  return (
    <>
      <h2>Garages (tenants)</h2>
      {error && <p className="error">{error}</p>}
      <div className="card row">
        <div>
          <label>Search</label>
          <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Name or phone" />
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-end' }}>
          <button type="button" className="btn secondary" onClick={load}>
            Search
          </button>
        </div>
      </div>

      <div className="card">
        <h3>Create garage</h3>
        <div className="row">
          <div>
            <label>Garage name</label>
            <input
              value={form.business_name}
              onChange={(e) => setForm({ ...form, business_name: e.target.value })}
            />
          </div>
          <div>
            <label>Owner first name</label>
            <input
              value={form.first_name}
              onChange={(e) => setForm({ ...form, first_name: e.target.value })}
            />
          </div>
        </div>
        <div className="row">
          <div>
            <label>Owner phone</label>
            <input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
          </div>
          <div>
            <label>Plan slug</label>
            <input value={form.plan_slug} onChange={(e) => setForm({ ...form, plan_slug: e.target.value })} />
          </div>
        </div>
        <button
          type="button"
          className="btn"
          onClick={async () => {
            await api.createTenant(form);
            setForm({ business_name: '', first_name: '', phone: '', plan_slug: 'starter', status: 'active' });
            load();
          }}
        >
          Create garage
        </button>
      </div>

      <div className="card">
        <table>
          <thead>
            <tr>
              <th>Garage</th>
              <th>Owner</th>
              <th>Plan</th>
              <th>Status</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {tenants.map((t) => (
              <tr key={t.uuid}>
                <td>{t.business_name}</td>
                <td>{t.owner?.phone ?? '—'}</td>
                <td>{t.subscription?.plan_name ?? '—'}</td>
                <td>{t.status}</td>
                <td>
                  <button type="button" className="btn secondary" onClick={() => openTenant(t)}>
                    Manage
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selected && (
        <div className="card">
          <h3>{selected.business_name}</h3>
          <p style={{ fontSize: 13, color: '#8891a0' }}>UUID: {selected.uuid}</p>
          <div className="row">
            <button
              type="button"
              className="btn secondary"
              onClick={async () => {
                await api.resetTenant(selected.uuid, true);
                alert('Operational data cleared; onboarding reset.');
                load();
              }}
            >
              Reset data + onboarding
            </button>
            <button
              type="button"
              className="btn danger"
              onClick={async () => {
                if (!confirm('Delete this garage permanently?')) return;
                await api.deleteTenant(selected.uuid);
                setSelected(null);
                load();
              }}
            >
              Delete garage
            </button>
          </div>
          <h4>Staff users</h4>
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Phone</th>
                <th>Role</th>
                <th>PIN setup</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.uuid}>
                  <td>
                    {u.first_name} {u.last_name}
                  </td>
                  <td>{u.phone}</td>
                  <td>{u.role}</td>
                  <td>{u.requires_pin_setup ? 'Pending' : 'Done'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}

function PlansPanel() {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [form, setForm] = useState({
    name: '',
    slug: '',
    price: 999,
    trial_days: 14,
    max_users: 5,
    status: 'active',
  });

  const load = async () => {
    const res = await api.plans();
    setPlans(res.data);
  };

  useEffect(() => {
    load();
  }, []);

  return (
    <>
      <h2>Subscription plans</h2>
      <div className="card">
        <h3>Add plan</h3>
        <div className="row">
          <div>
            <label>Name</label>
            <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          </div>
          <div>
            <label>Slug</label>
            <input value={form.slug} onChange={(e) => setForm({ ...form, slug: e.target.value })} />
          </div>
        </div>
        <button
          type="button"
          className="btn"
          onClick={async () => {
            await api.createPlan(form);
            load();
          }}
        >
          Save plan
        </button>
      </div>
      <div className="card">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Slug</th>
              <th>Price</th>
              <th>Trial</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {plans.map((p) => (
              <tr key={p.uuid}>
                <td>{p.name}</td>
                <td>{p.slug}</td>
                <td>₹{p.price}</td>
                <td>{p.trial_days}d</td>
                <td>{p.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}

function StoragePanel() {
  const [disk, setDisk] = useState('public');
  const [prefix, setPrefix] = useState('');
  const [tenantUuid, setTenantUuid] = useState('');
  const [files, setFiles] = useState<{ path: string; size: number }[]>([]);

  const load = async () => {
    const res = await api.storageFiles(disk, prefix, tenantUuid || undefined);
    setFiles(res.data.files);
  };

  return (
    <>
      <h2>Storage browser</h2>
      <div className="card row">
        <div>
          <label>Disk</label>
          <select value={disk} onChange={(e) => setDisk(e.target.value)}>
            <option value="public">public</option>
            <option value="local">local</option>
            <option value="s3">s3</option>
          </select>
        </div>
        <div>
          <label>Prefix / folder</label>
          <input value={prefix} onChange={(e) => setPrefix(e.target.value)} placeholder="invoices/" />
        </div>
        <div>
          <label>Tenant UUID (optional)</label>
          <input value={tenantUuid} onChange={(e) => setTenantUuid(e.target.value)} />
        </div>
      </div>
      <button type="button" className="btn secondary" onClick={load}>
        List files
      </button>
      <div className="card" style={{ marginTop: 16 }}>
        <table>
          <thead>
            <tr>
              <th>Path</th>
              <th>Size</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {files.map((f) => (
              <tr key={f.path}>
                <td>{f.path}</td>
                <td>{f.size}</td>
                <td>
                  <button
                    type="button"
                    className="btn danger"
                    onClick={async () => {
                      if (!confirm(`Delete ${f.path}?`)) return;
                      await api.deleteFile(disk, f.path);
                      load();
                    }}
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
