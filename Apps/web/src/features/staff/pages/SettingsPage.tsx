import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  Alert,
  Button,
  EmptyState,
  LoadingState,
  Modal,
  PageSection,
  StatusBadge,
  Table,
  THead,
  TRow,
  TH,
  TD,
} from '@/components/ui';
import { FieldLabel, SelectInput, TextInput } from '@/components/ui/FormField';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { customerName, initials } from '@/lib/format';

type SettingsTab = 'profile' | 'team' | 'integrations';

const SETTINGS_SECTIONS: { id: SettingsTab; label: string; hint: string }[] = [
  { id: 'profile', label: 'Garage profile', hint: 'Identity, contact, and tax details' },
  { id: 'team', label: 'Team & access', hint: 'Staff logins and roles' },
  { id: 'integrations', label: 'Integrations', hint: 'Customer messaging channels' },
];

const STAFF_ROLES = [
  { value: 'technician', label: 'Technician' },
  { value: 'service_advisor', label: 'Service advisor' },
];

function roleLabel(role?: string): string {
  if (!role) {
    return 'Staff';
  }
  return role.replace(/_/g, ' ');
}

function SettingsHero(props: { profile: JsonMap }) {
  const subscription = (props.profile.subscription as JsonMap | undefined) ?? {};
  const location = [props.profile.city, props.profile.state].filter(Boolean).join(', ');

  return (
    <div className="settings-hero">
      <div className="settings-hero-mark" aria-hidden>
        {initials(String(props.profile.business_name ?? 'GF'))}
      </div>
      <div className="settings-hero-body">
        <h3>{String(props.profile.business_name ?? 'Your garage')}</h3>
        <p className="muted">
          {[location, props.profile.phone ? String(props.profile.phone) : null].filter(Boolean).join(' · ') ||
            'Complete your garage profile below'}
        </p>
      </div>
      <div className="settings-hero-meta">
        {subscription.plan_name ? <span className="chip active">{String(subscription.plan_name)} plan</span> : null}
        {props.profile.gst_number ? <span className="chip">GST {String(props.profile.gst_number)}</span> : null}
      </div>
    </div>
  );
}

export function SettingsPage() {
  const token = useStaffToken();
  const [tab, setTab] = useState<SettingsTab>('profile');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const [message, setMessage] = useState<string>();
  const [showAddStaff, setShowAddStaff] = useState(false);
  const [showEditStaff, setShowEditStaff] = useState(false);
  const [editingStaffUuid, setEditingStaffUuid] = useState('');

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
    enabled: token.length > 0,
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

  const profile = profileQuery.data;
  const staffMembers = staffQuery.data ?? [];

  useEffect(() => {
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
  }, [profile]);

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
      setMessage('Garage profile saved.');
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
      setShowAddStaff(false);
      setMessage('Team member added.');
      await staffQuery.refetch();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  function openEditStaff(member: JsonMap) {
    setEditingStaffUuid(String(member.uuid));
    setStaffForm({
      first_name: String(member.first_name ?? ''),
      last_name: String(member.last_name ?? ''),
      phone: String(member.phone ?? ''),
      email: String(member.email ?? ''),
      role: String(member.role ?? 'technician'),
      pin: '',
    });
    setShowEditStaff(true);
  }

  async function updateStaff(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    setMessage(undefined);
    try {
      await apiRequest(`/staff/${editingStaffUuid}`, {
        method: 'PATCH',
        token,
        body: {
          first_name: staffForm.first_name.trim(),
          last_name: staffForm.last_name.trim(),
          phone: staffForm.phone.trim(),
          role: staffForm.role,
          ...(staffForm.email.trim() ? { email: staffForm.email.trim() } : {}),
        },
      });
      setShowEditStaff(false);
      setMessage('Team member updated.');
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
    <StaffPage title="Settings" subtitle="Garage profile, team, and integrations">
      <div className="settings-layout">
        <aside className="settings-nav-panel">
          <nav className="settings-nav" aria-label="Settings sections">
            {SETTINGS_SECTIONS.map((section) => (
              <button
                key={section.id}
                type="button"
                className={`settings-nav-item ${tab === section.id ? 'active' : ''}`.trim()}
                onClick={() => {
                  setTab(section.id);
                  setError(undefined);
                  setMessage(undefined);
                }}
              >
                <span className="settings-nav-label">{section.label}</span>
                <span className="settings-nav-hint">{section.hint}</span>
              </button>
            ))}
          </nav>

          <div className="settings-nav-footer">
            <Link to="/vehicles" className="settings-quick-link">
              Manage fleet vehicles →
            </Link>
            <Link to="/audit" className="settings-quick-link">
              View audit log →
            </Link>
          </div>
        </aside>

        <div className="settings-main">
          {profileQuery.isLoading ? <LoadingState label="Loading garage settings..." /> : null}
          {profile ? <SettingsHero profile={profile} /> : null}

          {message ? <Alert variant="success">{message}</Alert> : null}
          {error ? <Alert variant="error">{error}</Alert> : null}

          {tab === 'profile' ? (
            <form className="settings-sections" onSubmit={(event) => void saveProfile(event)}>
              <PageSection title="Business identity" subtitle="Shown on invoices and customer communications">
                <div className="form-grid">
                  <div style={{ gridColumn: '1 / -1' }}>
                    <FieldLabel htmlFor="settings-business-name">Business name</FieldLabel>
                    <TextInput
                      id="settings-business-name"
                      required
                      value={profileForm.business_name}
                      onChange={(event) => setProfileForm({ ...profileForm, business_name: event.target.value })}
                    />
                  </div>
                  <div>
                    <FieldLabel htmlFor="settings-phone">Workshop phone</FieldLabel>
                    <TextInput
                      id="settings-phone"
                      value={profileForm.phone}
                      onChange={(event) => setProfileForm({ ...profileForm, phone: event.target.value })}
                    />
                  </div>
                  <div>
                    <FieldLabel htmlFor="settings-email">Business email</FieldLabel>
                    <TextInput
                      id="settings-email"
                      type="email"
                      value={profileForm.email}
                      onChange={(event) => setProfileForm({ ...profileForm, email: event.target.value })}
                    />
                  </div>
                </div>
              </PageSection>

              <PageSection title="Workshop location" subtitle="Used for customer directions and tax jurisdiction">
                <div className="form-grid">
                  <div style={{ gridColumn: '1 / -1' }}>
                    <FieldLabel htmlFor="settings-address">Street address</FieldLabel>
                    <TextInput
                      id="settings-address"
                      value={profileForm.address}
                      onChange={(event) => setProfileForm({ ...profileForm, address: event.target.value })}
                    />
                  </div>
                  <div>
                    <FieldLabel htmlFor="settings-city">City</FieldLabel>
                    <TextInput
                      id="settings-city"
                      value={profileForm.city}
                      onChange={(event) => setProfileForm({ ...profileForm, city: event.target.value })}
                    />
                  </div>
                  <div>
                    <FieldLabel htmlFor="settings-state">State</FieldLabel>
                    <TextInput
                      id="settings-state"
                      value={profileForm.state}
                      onChange={(event) => setProfileForm({ ...profileForm, state: event.target.value })}
                    />
                  </div>
                  <div>
                    <FieldLabel htmlFor="settings-pincode">Pincode</FieldLabel>
                    <TextInput
                      id="settings-pincode"
                      value={profileForm.pincode}
                      onChange={(event) => setProfileForm({ ...profileForm, pincode: event.target.value })}
                    />
                  </div>
                </div>
              </PageSection>

              <PageSection title="Tax & billing" subtitle="GST details for compliant invoices">
                <div className="form-grid form-grid--stack">
                  <div>
                    <FieldLabel htmlFor="settings-gst">GST number</FieldLabel>
                    <TextInput
                      id="settings-gst"
                      placeholder="e.g. 27AABCU9603R1ZM"
                      value={profileForm.gst_number}
                      onChange={(event) => setProfileForm({ ...profileForm, gst_number: event.target.value })}
                    />
                  </div>
                </div>
              </PageSection>

              <div className="settings-form-actions">
                <Button type="submit" disabled={saving}>
                  {saving ? 'Saving...' : 'Save garage profile'}
                </Button>
              </div>
            </form>
          ) : null}

          {tab === 'team' ? (
            <div className="settings-sections">
              <PageSection
                title="Team members"
                subtitle={`${staffMembers.length} staff with app access`}
                action={
                  <Button type="button" onClick={() => setShowAddStaff(true)}>
                    Add team member
                  </Button>
                }
              >
                {staffQuery.isLoading ? <LoadingState label="Loading team..." /> : null}
                {!staffQuery.isLoading && staffMembers.length === 0 ? (
                  <EmptyState
                    title="No team members yet"
                    description="Add technicians and service advisors so they can log in with their PIN."
                    action={
                      <Button type="button" onClick={() => setShowAddStaff(true)}>
                        Add first team member
                      </Button>
                    }
                  />
                ) : null}
                {staffMembers.length > 0 ? (
                  <Table className="table-spaced">
                    <THead>
                      <TRow>
                        <TH>Member</TH>
                        <TH>Phone</TH>
                        <TH>Role</TH>
                        <TH>Actions</TH>
                      </TRow>
                    </THead>
                    <tbody>
                      {staffMembers.map((member) => {
                        const name = customerName(member);
                        return (
                          <TRow key={String(member.uuid)}>
                            <TD>
                              <span className="avatar-chip">{initials(name)}</span>
                              {name}
                            </TD>
                            <TD>{String(member.phone ?? '-')}</TD>
                            <TD>
                              <span className="chip">{roleLabel(String(member.role ?? 'staff'))}</span>
                            </TD>
                            <TD>
                              <Button type="button" variant="ghost" onClick={() => openEditStaff(member)}>
                                Edit
                              </Button>
                            </TD>
                          </TRow>
                        );
                      })}
                    </tbody>
                  </Table>
                ) : null}
              </PageSection>
            </div>
          ) : null}

          {tab === 'integrations' ? (
            <div className="settings-sections">
              {whatsappQuery.isLoading ? <LoadingState label="Loading integrations..." /> : null}
              <div className="integration-card">
                <div className="integration-card-header">
                  <div>
                    <h4>WhatsApp Business</h4>
                    <p className="muted">Send job updates and appointment reminders to customers</p>
                  </div>
                  <StatusBadge status={whatsappForm.enabled ? 'active' : 'draft'} />
                </div>

                <form className="integration-card-body" onSubmit={(event) => void saveWhatsApp(event)}>
                  <label className="toggle-row">
                    <div>
                      <strong>Enable WhatsApp messaging</strong>
                      <p className="form-hint">Turn on when your Meta Business credentials are configured.</p>
                    </div>
                    <input
                      type="checkbox"
                      className="toggle-input"
                      checked={whatsappForm.enabled}
                      onChange={(event) => setWhatsappForm({ ...whatsappForm, enabled: event.target.checked })}
                    />
                  </label>

                  <div className="form-grid form-grid--stack">
                    <div>
                      <FieldLabel htmlFor="wa-phone-id">Phone number ID</FieldLabel>
                      <TextInput
                        id="wa-phone-id"
                        value={whatsappForm.phone_number_id}
                        onChange={(event) => setWhatsappForm({ ...whatsappForm, phone_number_id: event.target.value })}
                      />
                    </div>
                    <div>
                      <FieldLabel htmlFor="wa-business-id">Business account ID</FieldLabel>
                      <TextInput
                        id="wa-business-id"
                        value={whatsappForm.business_account_id}
                        onChange={(event) =>
                          setWhatsappForm({ ...whatsappForm, business_account_id: event.target.value })
                        }
                      />
                    </div>
                    <div>
                      <FieldLabel htmlFor="wa-token">Access token</FieldLabel>
                      <TextInput
                        id="wa-token"
                        type="password"
                        autoComplete="off"
                        value={whatsappForm.access_token}
                        onChange={(event) => setWhatsappForm({ ...whatsappForm, access_token: event.target.value })}
                      />
                    </div>
                  </div>

                  <div className="settings-form-actions settings-form-actions--inline">
                    <Button type="submit" disabled={saving}>
                      {saving ? 'Saving...' : 'Save integration'}
                    </Button>
                    <Button type="button" variant="outline" onClick={() => void testWhatsApp()} disabled={saving}>
                      Test connection
                    </Button>
                  </div>
                </form>
              </div>
            </div>
          ) : null}
        </div>
      </div>

      <Modal
        open={showAddStaff}
        onClose={() => setShowAddStaff(false)}
        title="Add team member"
        subtitle="They will sign in with phone number and a 6-digit PIN"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setShowAddStaff(false)}>
              Cancel
            </Button>
            <Button type="submit" form="add-staff-form" disabled={saving}>
              {saving ? 'Adding...' : 'Add member'}
            </Button>
          </>
        }
      >
        <form id="add-staff-form" className="form-grid form-grid--stack" onSubmit={(event) => void addStaff(event)}>
          <div>
            <FieldLabel htmlFor="staff-first-name">First name</FieldLabel>
            <TextInput
              id="staff-first-name"
              required
              value={staffForm.first_name}
              onChange={(event) => setStaffForm({ ...staffForm, first_name: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="staff-last-name">Last name</FieldLabel>
            <TextInput
              id="staff-last-name"
              value={staffForm.last_name}
              onChange={(event) => setStaffForm({ ...staffForm, last_name: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="staff-phone">Phone</FieldLabel>
            <TextInput
              id="staff-phone"
              required
              value={staffForm.phone}
              onChange={(event) => setStaffForm({ ...staffForm, phone: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="staff-email">Email (optional)</FieldLabel>
            <TextInput
              id="staff-email"
              type="email"
              value={staffForm.email}
              onChange={(event) => setStaffForm({ ...staffForm, email: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="staff-role">Role</FieldLabel>
            <SelectInput
              id="staff-role"
              value={staffForm.role}
              onChange={(event) => setStaffForm({ ...staffForm, role: event.target.value })}
            >
              {STAFF_ROLES.map((role) => (
                <option key={role.value} value={role.value}>
                  {role.label}
                </option>
              ))}
            </SelectInput>
          </div>
          <div>
            <FieldLabel htmlFor="staff-pin">6-digit PIN</FieldLabel>
            <TextInput
              id="staff-pin"
              required
              inputMode="numeric"
              maxLength={6}
              value={staffForm.pin}
              onChange={(event) => setStaffForm({ ...staffForm, pin: event.target.value.replace(/\D/g, '').slice(0, 6) })}
            />
            <p className="form-hint">Share this PIN securely — staff use it to log into GarageFlow.</p>
          </div>
        </form>
      </Modal>

      <Modal
        open={showEditStaff}
        onClose={() => setShowEditStaff(false)}
        title="Edit team member"
        subtitle="Update contact details and role"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setShowEditStaff(false)}>
              Cancel
            </Button>
            <Button type="submit" form="edit-staff-form" disabled={saving}>
              {saving ? 'Saving...' : 'Save changes'}
            </Button>
          </>
        }
      >
        <form id="edit-staff-form" className="form-grid form-grid--stack" onSubmit={(event) => void updateStaff(event)}>
          <div>
            <FieldLabel htmlFor="edit-staff-first">First name</FieldLabel>
            <TextInput
              id="edit-staff-first"
              required
              value={staffForm.first_name}
              onChange={(event) => setStaffForm({ ...staffForm, first_name: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="edit-staff-last">Last name</FieldLabel>
            <TextInput
              id="edit-staff-last"
              value={staffForm.last_name}
              onChange={(event) => setStaffForm({ ...staffForm, last_name: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="edit-staff-phone">Phone</FieldLabel>
            <TextInput
              id="edit-staff-phone"
              required
              value={staffForm.phone}
              onChange={(event) => setStaffForm({ ...staffForm, phone: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="edit-staff-email">Email</FieldLabel>
            <TextInput
              id="edit-staff-email"
              type="email"
              value={staffForm.email}
              onChange={(event) => setStaffForm({ ...staffForm, email: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="edit-staff-role">Role</FieldLabel>
            <SelectInput
              id="edit-staff-role"
              value={staffForm.role}
              onChange={(event) => setStaffForm({ ...staffForm, role: event.target.value })}
            >
              {STAFF_ROLES.map((role) => (
                <option key={role.value} value={role.value}>
                  {role.label}
                </option>
              ))}
            </SelectInput>
          </div>
        </form>
      </Modal>
    </StaffPage>
  );
}
