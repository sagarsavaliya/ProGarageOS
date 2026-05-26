import { Link, useParams } from 'react-router-dom';
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Alert, Button, Card, Modal, StatusBadge, Table, THead, TRow, TH, TD } from '@/components/ui';
import { FieldLabel, TextArea, TextInput } from '@/components/ui/FormField';
import { AddVehicleModal } from '@/features/staff/components/AddVehicleModal';
import { StaffPage, useStaffToken } from '@/features/staff/components/StaffPage';
import { apiRequest, asData, type JsonMap } from '@/lib/api';
import { useDetail } from '@/lib/hooks';
import { customerName, vehicleLabel } from '@/lib/format';

export function CustomerDetailPage() {
  const { uuid = '' } = useParams();
  const token = useStaffToken();
  const [showAddVehicle, setShowAddVehicle] = useState(false);
  const [showEditCustomer, setShowEditCustomer] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const [message, setMessage] = useState<string>();
  const [editForm, setEditForm] = useState({
    first_name: '',
    last_name: '',
    email: '',
    phone_secondary: '',
    internal_notes: '',
  });
  const detailQuery = useDetail(`/customers/${uuid}`, token, uuid.length > 0);
  const customer = asData<JsonMap>(detailQuery.data ?? {});

  const historyQuery = useQuery({
    queryKey: ['customer-history', uuid, token],
    enabled: uuid.length > 0 && token.length > 0,
    queryFn: async () => {
      const payload = await apiRequest(`/customers/${uuid}/service-history`, { token });
      return asData<JsonMap[]>(payload) ?? [];
    },
  });

  const vehicles = (customer.vehicles as JsonMap[] | undefined) ?? [];
  const history = historyQuery.data ?? [];

  function openEditCustomer() {
    setEditForm({
      first_name: String(customer.first_name ?? ''),
      last_name: String(customer.last_name ?? ''),
      email: String(customer.email ?? ''),
      phone_secondary: String(customer.phone_secondary ?? ''),
      internal_notes: String(customer.internal_notes ?? ''),
    });
    setShowEditCustomer(true);
  }

  async function saveCustomer(event: React.FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(undefined);
    try {
      await apiRequest(`/customers/${uuid}`, {
        method: 'PUT',
        token,
        body: {
          first_name: editForm.first_name.trim(),
          last_name: editForm.last_name.trim(),
          ...(editForm.email.trim() ? { email: editForm.email.trim() } : {}),
          ...(editForm.phone_secondary.trim() ? { phone_secondary: editForm.phone_secondary.trim() } : {}),
          ...(editForm.internal_notes.trim() ? { internal_notes: editForm.internal_notes.trim() } : {}),
        },
      });
      await detailQuery.refetch();
      setShowEditCustomer(false);
      setMessage('Customer profile saved.');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <StaffPage title={customerName(customer)} subtitle="Customer profile and service history">
      <div className="toolbar">
        <Link to="/customers">
          <Button type="button" variant="outline">
            Back
          </Button>
        </Link>
        <Link to={`/jobs/new?customer=${uuid}`}>
          <Button type="button">New job</Button>
        </Link>
        <Button type="button" variant="outline" onClick={() => setShowAddVehicle(true)}>
          Add vehicle
        </Button>
        <Button type="button" variant="outline" onClick={openEditCustomer}>
          Edit customer
        </Button>
      </div>

      {message ? <Alert variant="success">{message}</Alert> : null}
      {error ? <Alert variant="error">{error}</Alert> : null}

      {detailQuery.isLoading ? <p className="muted">Loading customer...</p> : null}

      <div className="detail-grid">
        <Card>
          <h3>Contact</h3>
          <div className="stack" style={{ marginTop: 12 }}>
            <div className="line-item">
              <span>Phone</span>
              <span>{String(customer.phone_primary ?? customer.phone ?? '-')}</span>
            </div>
            <div className="line-item">
              <span>Email</span>
              <span>{String(customer.email ?? '-')}</span>
            </div>
            <div className="line-item">
              <span>Last visit</span>
              <span>{String(customer.last_visited_at ?? '-')}</span>
            </div>
          </div>
        </Card>

        <Card>
          <div className="section-header">
            <h3>Vehicles</h3>
            {vehicles.length === 0 ? (
              <Button type="button" variant="outline" onClick={() => setShowAddVehicle(true)}>
                Add vehicle
              </Button>
            ) : null}
          </div>
          {vehicles.length === 0 ? <p className="muted">No vehicles registered.</p> : null}
          <div className="stack" style={{ marginTop: 12 }}>
            {vehicles.map((vehicle) => (
              <Link key={String(vehicle.uuid)} to={`/vehicles/${String(vehicle.uuid)}`} className="line-item">
                <span>{vehicleLabel(vehicle)}</span>
                <StatusBadge status={vehicle.is_active === false ? 'cancelled' : 'active'} />
              </Link>
            ))}
          </div>
        </Card>
      </div>

      <Card>
        <h3>Service history</h3>
        {historyQuery.isLoading ? <p className="muted">Loading history...</p> : null}
        {!historyQuery.isLoading && history.length === 0 ? <p className="muted">No service history yet.</p> : null}
        {history.length > 0 ? (
          <Table className="table-spaced">
            <THead>
              <TRow>
                <TH>Job</TH>
                <TH>Vehicle</TH>
                <TH>Status</TH>
                <TH>Date</TH>
              </TRow>
            </THead>
            <tbody>
              {history.map((entry) => (
                <TRow key={String(entry.uuid ?? entry.job_uuid)}>
                  <TD>
                    <Link to={`/jobs/${String(entry.job_uuid ?? entry.uuid)}`}>
                      {String(entry.job_number ?? entry.uuid)}
                    </Link>
                  </TD>
                  <TD>{vehicleLabel((entry.vehicle as JsonMap) ?? entry)}</TD>
                  <TD>
                    <StatusBadge status={String(entry.status ?? 'draft')} />
                  </TD>
                  <TD>{String(entry.completed_at ?? entry.created_at ?? '-')}</TD>
                </TRow>
              ))}
            </tbody>
          </Table>
        ) : null}
      </Card>

      <AddVehicleModal
        open={showAddVehicle}
        token={token}
        customerUuid={uuid}
        customerLabel={customerName(customer)}
        onClose={() => setShowAddVehicle(false)}
        onCreated={() => {
          void detailQuery.refetch();
        }}
      />

      <Modal
        open={showEditCustomer}
        onClose={() => setShowEditCustomer(false)}
        title="Edit customer"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setShowEditCustomer(false)}>
              Cancel
            </Button>
            <Button type="submit" form="edit-customer-form" disabled={saving}>
              {saving ? 'Saving...' : 'Save customer'}
            </Button>
          </>
        }
      >
        <form id="edit-customer-form" className="form-grid form-grid--stack" onSubmit={(event) => void saveCustomer(event)}>
          <div className="form-grid">
            <div>
              <FieldLabel htmlFor="cust-first">First name</FieldLabel>
              <TextInput
                id="cust-first"
                required
                value={editForm.first_name}
                onChange={(event) => setEditForm({ ...editForm, first_name: event.target.value })}
              />
            </div>
            <div>
              <FieldLabel htmlFor="cust-last">Last name</FieldLabel>
              <TextInput
                id="cust-last"
                value={editForm.last_name}
                onChange={(event) => setEditForm({ ...editForm, last_name: event.target.value })}
              />
            </div>
          </div>
          <div>
            <FieldLabel htmlFor="cust-email">Email</FieldLabel>
            <TextInput
              id="cust-email"
              type="email"
              value={editForm.email}
              onChange={(event) => setEditForm({ ...editForm, email: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="cust-phone2">Secondary phone</FieldLabel>
            <TextInput
              id="cust-phone2"
              value={editForm.phone_secondary}
              onChange={(event) => setEditForm({ ...editForm, phone_secondary: event.target.value })}
            />
          </div>
          <div>
            <FieldLabel htmlFor="cust-notes">Internal notes</FieldLabel>
            <TextArea
              id="cust-notes"
              rows={3}
              value={editForm.internal_notes}
              onChange={(event) => setEditForm({ ...editForm, internal_notes: event.target.value })}
            />
          </div>
        </form>
      </Modal>
    </StaffPage>
  );
}
