import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Button, Card, Table, THead, TRow, TH, TD } from '@/components/ui';
import { FieldLabel, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { customerName } from '@/lib/format';

type SettingsTab = 'profile' | 'team' | 'integrations';

export function SettingsPage() {
  const token = useStaffToken();
  const [tab, setTab] = useState<SettingsTab>('profile');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const [message, setMessage] = useState<string>();

  const profileQuery = useQuery({
    queryKey: ['tenant-profile', token],
    enabled: token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest('/tenant/profile', { token });
      return asData<JsonMap>(payload);
    },
  });

  const staffQuery = useQuery({
    queryKey: ['staff-list', token],
    enabled: token.length > 0 && tab === 'team',
    queryFn: async () => {
      const payload = await apiRequest('/staff', { token });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const whatsappQuery = useQuery({
    queryKey: ['whatsapp-integration', token],
    enabled: token.length > 0 && tab === 'integrations',
    queryFn: async () => {
      const payload = await apiRequest('/integrations/whatsapp', { token });
      return asData<JsonMap>(payload);
    },
  });

  const [profileForm, setProfileForm] = useState({
    business_name: '',
    phone: '',
    email: '',
    address: '',
    city: '',
    state: '',
    pincode: '',
    gst_number: '',
  });

  const [staffForm, setStaffForm] = useState({
    first_name: '',
    last_name: '',
    phone: '',
    email: '',
    role: 'technician',
    pin: '',
  });

  const [whatsappForm, setWhatsappForm] = useState({
    enabled: false,
    phone_number_id: '',
    business_account_id: '',
    access_token: '',
  });

  useEffect(() => {
    const profile = profileQuery.data;
    if (!profile) {
      return;
    }
    setProfileForm({
      business_name: String(profile.business_name ?? ''),
      phone: String(profile.phone ?? ''),
      email: String(profile.email ?? ''),
      address: String(profile.address ?? ''),
      city: String(profile.city ?? ''),
      state: String(profile.state ?? ''),
      pincode: String(profile.pincode ?? ''),
      gst_number: String(profile.gst_number ?? ''),
    });
  }, [profileQuery.data]);

  useEffect(() => {
    const data = whatsappQuery.data;
    if (!data) {
      return;
    }
    setWhatsappForm({
      enabled: Boolean(data.enabled),
      phone_number_id: String(data.phone_number_id ?? ''),
      business_account_id: String(data.business_account_id ?? ''),
      access_token: String(data.access_token ?? ''),
    });
  }, [whatsappQuery.data]);

  async function saveProfile(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    setMessage(undefined);
    try {
      await apiRequest('/tenant/profile', { method: 'PUT', token, body: profileForm });
      setMessage('Profile updated.');
      await profileQuery.refetch();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function addStaff(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    setMessage(undefined);
    try {
      await apiRequest('/staff', {
        method: 'POST',
        token,
        body: {
          first_name: staffForm.first_name.trim(),
          last_name: staffForm.last_name.trim(),
          phone: staffForm.phone.trim(),
          role: staffForm.role,
          pin: staffForm.pin,
          ...(staffForm.email.trim() ? { email: staffForm.email.trim() } : {}),
        },
      });
      setStaffForm({ first_name: '', last_name: '', phone: '', email: '', role: 'technician', pin: '' });
      setMessage('Team member added.');
      await staffQuery.refetch();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function saveWhatsApp(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    setMessage(undefined);
    try {
      await apiRequest('/integrations/whatsapp', { method: 'PUT', token, body: whatsappForm });
      setMessage('WhatsApp integration saved.');
      await whatsappQuery.refetch();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function testWhatsApp() {
    setSaving(true);
    setError(undefined);
    setMessage(undefined);
    try {
      const payload = await apiRequest('/integrations/whatsapp/test', { method: 'POST', token });
      const data = asData<JsonMap>(payload);
      setMessage(String(data.message ?? 'Connection test completed.'));
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <StaffPage title="Settings" subtitle="Profile, team, and integrations">
      <div className="tabs">
        {(['profile', 'team', 'integrations'] as SettingsTab[]).map((item) => (
          <button key={item} type="button" className={`tab ${tab === item ? 'active' : ''}`} onClick={() => setTab(item)}>
            {item.charAt(0).toUpperCase() + item.slice(1)}
          </button>
        ))}
      </div>

      {message ? <p className="muted">{message}</p> : null}
      {error ? <p className="error-text">{error}</p> : null}

      {tab === 'profile' ? (
        <Card>
          <form className="form-grid" onSubmit={(event) => void saveProfile(event)}>
            <div>
              <FieldLabel>Business name</FieldLabel>
              <TextInput
                required
                value={profileForm.business_name}
                onChange={(event) => setProfileForm({ ...profileForm, business_name: event.target.value })}
              />
            </div>
            <div>
              <FieldLabel>Phone</FieldLabel>
              <TextInput value={profileForm.phone} onChange={(event) => setProfileForm({ ...profileForm, phone: event.target.value })} />
            </div>
            <div>
              <FieldLabel>Email</FieldLabel>
              <TextInput value={profileForm.email} onChange={(event) => setProfileForm({ ...profileForm, email: event.target.value })} />
            </div>
            <div>
              <FieldLabel>Address</FieldLabel>
              <TextInput value={profileForm.address} onChange={(event) => setProfileForm({ ...profileForm, address: event.target.value })} />
            </div>
            <div>
              <FieldLabel>City</FieldLabel>
              <TextInput value={profileForm.city} onChange={(event) => setProfileForm({ ...profileForm, city: event.target.value })} />
            </div>
            <div>
              <FieldLabel>State</FieldLabel>
              <TextInput value={profileForm.state} onChange={(event) => setProfileForm({ ...profileForm, state: event.target.value })} />
            </div>
            <div>
              <FieldLabel>Pincode</FieldLabel>
              <TextInput value={profileForm.pincode} onChange={(event) => setProfileForm({ ...profileForm, pincode: event.target.value })} />
            </div>
            <div>
              <FieldLabel>GST number</FieldLabel>
              <TextInput
                value={profileForm.gst_number}
                onChange={(event) => setProfileForm({ ...profileForm, gst_number: event.target.value })}
              />
            </div>
            <div className="toolbar">
              <Button type="submit" disabled={saving}>
                {saving ? 'Saving...' : 'Save profile'}
              </Button>
              <Link to="/vehicles">
                <Button type="button" variant="outline">
                  Manage fleet
                </Button>
              </Link>
            </div>
          </form>
        </Card>
      ) : null}

      {tab === 'team' ? (
        <div className="stack">
          <Card>
            <h3>Team members</h3>
            {(staffQuery.data ?? []).length === 0 ? <p className="muted">No staff listed.</p> : null}
            {(staffQuery.data ?? []).length > 0 ? (
              <Table>
                <THead>
                  <TRow>
                    <TH>Name</TH>
                    <TH>Phone</TH>
                    <TH>Role</TH>
                  </TRow>
                </THead>
                <tbody>
                  {(staffQuery.data ?? []).map((member) => (
                    <TRow key={String(member.uuid)}>
                      <TD>{customerName(member)}</TD>
                      <TD>{String(member.phone ?? '-')}</TD>
                      <TD>{String(member.role ?? '-')}</TD>
                    </TRow>
                  ))}
                </tbody>
              </Table>
            ) : null}
          </Card>

          <Card>
            <h3>Add team member</h3>
            <form className="form-grid" style={{ marginTop: 12 }} onSubmit={(event) => void addStaff(event)}>
              <div>
                <FieldLabel>First name</FieldLabel>
                <TextInput
                  required
                  value={staffForm.first_name}
                  onChange={(event) => setStaffForm({ ...staffForm, first_name: event.target.value })}
                />
              </div>
              <div>
                <FieldLabel>Last name</FieldLabel>
                <TextInput value={staffForm.last_name} onChange={(event) => setStaffForm({ ...staffForm, last_name: event.target.value })} />
              </div>
              <div>
                <FieldLabel>Phone</FieldLabel>
                <TextInput required value={staffForm.phone} onChange={(event) => setStaffForm({ ...staffForm, phone: event.target.value })} />
              </div>
              <div>
                <FieldLabel>Email</FieldLabel>
                <TextInput value={staffForm.email} onChange={(event) => setStaffForm({ ...staffForm, email: event.target.value })} />
              </div>
              <div>
                <FieldLabel>Role</FieldLabel>
                <TextInput value={staffForm.role} onChange={(event) => setStaffForm({ ...staffForm, role: event.target.value })} />
              </div>
              <div>
                <FieldLabel>PIN</FieldLabel>
                <TextInput required value={staffForm.pin} onChange={(event) => setStaffForm({ ...staffForm, pin: event.target.value })} />
              </div>
              <Button type="submit" disabled={saving}>
                {saving ? 'Adding...' : 'Add staff'}
              </Button>
            </form>
          </Card>
        </div>
      ) : null}

      {tab === 'integrations' ? (
        <Card>
          <h3>WhatsApp</h3>
          <form className="form-grid" style={{ marginTop: 12 }} onSubmit={(event) => void saveWhatsApp(event)}>
            <label className="line-item">
              <span>Enabled</span>
              <input
                type="checkbox"
                checked={whatsappForm.enabled}
                onChange={(event) => setWhatsappForm({ ...whatsappForm, enabled: event.target.checked })}
              />
            </label>
            <div>
              <FieldLabel>Phone number ID</FieldLabel>
              <TextInput
                value={whatsappForm.phone_number_id}
                onChange={(event) => setWhatsappForm({ ...whatsappForm, phone_number_id: event.target.value })}
              />
            </div>
            <div>
              <FieldLabel>Business account ID</FieldLabel>
              <TextInput
                value={whatsappForm.business_account_id}
                onChange={(event) => setWhatsappForm({ ...whatsappForm, business_account_id: event.target.value })}
              />
            </div>
            <div>
              <FieldLabel>Access token</FieldLabel>
              <TextInput
                value={whatsappForm.access_token}
                onChange={(event) => setWhatsappForm({ ...whatsappForm, access_token: event.target.value })}
              />
            </div>
            <div className="toolbar">
              <Button type="submit" disabled={saving}>
                {saving ? 'Saving...' : 'Save integration'}
              </Button>
              <Button type="button" variant="outline" onClick={() => void testWhatsApp()} disabled={saving}>
                Test connection
              </Button>
            </div>
          </form>
        </Card>
      ) : null}
    </StaffPage>
  );
}
